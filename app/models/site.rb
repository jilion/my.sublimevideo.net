class Site < ActiveRecord::Base
  extend ActiveSupport::Memoizable
  include SiteModules::Api
  include SiteModules::Invoice
  include SiteModules::Recurring
  include SiteModules::Referrer
  include SiteModules::Scope
  include SiteModules::Templates
  include SiteModules::Usage
  include SiteModules::Stats

  DEFAULT_DEV_DOMAINS = '127.0.0.1, localhost'
  PLAYER_MODES = %w[dev beta stable]

  # Versioning
  has_paper_trail :ignore => [:cdn_up_to_date, :license, :loader]

  attr_accessor :loader_needs_update, :license_needs_update
  attr_accessor :user_attributes, :charging_options, :transaction

  attr_accessible :hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :badged, :plan_id, :user_attributes

  uniquify :token, :chars => Array('a'..'z') + Array('0'..'9')

  mount_uploader :license, LicenseUploader
  mount_uploader :loader, LoaderUploader

  delegate :name, :to => :plan, :prefix => true
  delegate :video_views, :to => :plan, :prefix => true

  # ================
  # = Associations =
  # ================

  belongs_to :user, :validate => true, :autosave => true
  belongs_to :plan
  belongs_to :next_cycle_plan, :class_name => "Plan"
  belongs_to :pending_plan,    :class_name => "Plan"

  has_many :invoices, :class_name => "::Invoice"
  has_one  :last_invoice, :class_name => "::Invoice", :order => :created_at.desc

  # Mongoid associations
  def usages
    SiteUsage.where(site_id: id)
  end
  def referrers
    ::Referrer.where(site_id: id)
  end
  def stats
    SiteStat.where(t: token)
  end

  # ===============
  # = Validations =
  # ===============

  validates :user,        :presence => true
  validates :plan,        :presence => { :message => "Please choose a plan" }, :unless => :pending_plan_id?
  validates :player_mode, :inclusion => PLAYER_MODES

  validates :hostname,        :presence => { :if => proc { |s| s.in_or_will_be_in_paid_plan? } }, :hostname => true, :hostname_uniqueness => true
  validates :dev_hostnames,   :dev_hostnames => true
  validates :extra_hostnames, :extra_hostnames => true
  validates :badged,          :inclusion => [true], :if => :in_free_plan?

  validate  :validates_current_password

  # =============
  # = Callbacks =
  # =============

  before_validation :set_user_attributes
  before_validation :set_default_dev_hostnames, :unless => :dev_hostnames?
  before_validation :set_default_badged, :if => proc { |s| s.badged.nil? || s.in_free_plan? }

  before_save :prepare_cdn_update # in site_modules/templates
  before_save :clear_alerts_sent_at
  before_save :pend_plan_changes, :if => :pending_plan_id_changed? # in site_modules/invoice
  before_save :set_trial_started_at # in site_modules/invoice

  after_create :delay_ranks_update # in site_modules/templates

  after_save :create_and_charge_invoice # in site_modules/invoice
  after_save :execute_cdn_update # in site_modules/templates

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :active do
    event(:archive)   { transition [:active, :suspended] => :archived }
    event(:suspend)   { transition :active => :suspended }
    event(:unsuspend) { transition :suspended => :active }

    state :archived do
      validate :prevent_archive_with_non_paid_invoices
    end

    before_transition :on => :archive, :do => [:set_archived_at, :cancel_open_or_failed_invoices]

    after_transition  :to => [:suspended, :archived], :do => :delay_remove_loader_and_license # in site/templates
  end

  # =================
  # = Class Methods =
  # =================

  def self.to_backbone_json
    scoped.to_json(
      only: [:token, :hostname],
      methods: [:plan_video_views, :plan_month_cycle_start_time, :plan_month_cycle_end_time, :stats_retention_days, :stats_trial_start_time]
    )
  end

  # ====================
  # = Instance Methods =
  # ====================

  def hostname=(attribute)
    write_attribute(:hostname, Hostname.clean(attribute))
  end

  def extra_hostnames=(attribute)
    write_attribute(:extra_hostnames, Hostname.clean(attribute))
  end

  def dev_hostnames=(attribute)
    write_attribute(:dev_hostnames, Hostname.clean(attribute))
  end

  def path=(attribute)
    write_attribute :path, attribute.respond_to?(:to_s) ? attribute.to_s.downcase.gsub(/^\/|\/$/, '') : ''
  end

  def plan_id=(attribute)
    return if pending_plan_id? || invoices.not_paid.any?

    if attribute.to_s == attribute.to_i.to_s # id passed
      new_plan = Plan.find_by_id(attribute.to_i)
      return unless new_plan.standard_plan? || new_plan.free_plan? || new_plan.dev_plan?
    else # token passed
      new_plan = Plan.find_by_token(attribute)
    end

    if new_plan.present?
      if plan_id?
        case plan.upgrade?(new_plan)
        when true # Upgrade
          write_attribute(:pending_plan_id, new_plan.id)
          write_attribute(:next_cycle_plan_id, nil)
        when false # Downgrade
          if trial_not_started_or_in_trial? || !first_paid_plan_started_at?
            write_attribute(:pending_plan_id, new_plan.id)
          else
            write_attribute(:next_cycle_plan_id, new_plan.id)
          end
        when nil # Same plan, reset next_cycle_plan
          write_attribute(:next_cycle_plan_id, nil)
        end
      else
        # Creation
        write_attribute(:pending_plan_id, new_plan.id)
      end
    end
  end

  # Instantly change plan to sponsored_plan (no refund!)
  def sponsor!
    write_attribute(:pending_plan_id, Plan.sponsored_plan.id)
    write_attribute(:next_cycle_plan_id, nil)
    save_without_password_validation
  end

  def without_password_validation
    @skip_password_validation = true
    result = yield
    @skip_password_validation = false
    result
  end

  def save_without_password_validation
    without_password_validation { self.save }
  end

  def to_param
    token
  end

  def hostname_with_path_needed
    return nil if path?
    list = %w[web.me.com web.mac.com homepage.mac.com cargocollective.com]
    list.detect { |h| h == hostname || (extra_hostnames.present? && extra_hostnames.split(', ').include?(h)) }
  end

  def hostname_with_subdomain_needed
    return nil unless wildcard?
    list = %w[tumblr.com squarespace.com posterous.com blogspot.com typepad.com]
    list.detect { |h| h == hostname || (extra_hostnames.present? && extra_hostnames.split(', ').include?(h)) }
  end

  # Boolean helpers
  def need_path?
    hostname_with_path_needed.present?
  end

  def need_subdomain?
    hostname_with_subdomain_needed.present?
  end

  def archivable?
    invoices.waiting.empty? && (!first_paid_plan_started_at? || invoices.open_or_failed.empty?)
  end

  def recommended_plan_name
    if in_paid_plan?
      usages = last_30_days_billable_usages
      name = nil
      if usages.size >= 5
        Plan.standard_plans.order(:video_views.desc).each do |tested_plan|
          if usages.sum < tested_plan.video_views && usages.mean < tested_plan.daily_video_views
            name = plan.video_views < tested_plan.video_views ? tested_plan.name : nil
          end
        end

        if name.nil? && !in_custom_plan?
          biggest_standard_plan = Plan.standard_plans.order(:video_views.desc).first
          name = "custom" if usages.sum >= biggest_standard_plan.video_views || usages.mean >= biggest_standard_plan.daily_video_views
        end
      end
      name
    end
  end
  memoize :recommended_plan_name

  def plan_month_cycle_started_at
    cycle = trial_not_started_or_in_trial? ? 'none' : plan.read_attribute(:cycle) # strange error in specs when using .cycle

    case cycle
    when 'month'
      plan_cycle_started_at
    when 'year'
      plan_cycle_started_at + months_since(plan_cycle_started_at).months
    when 'none'
      (1.month - 1.day).ago.midnight
    end
  end

  def plan_month_cycle_start_time
    plan_month_cycle_started_at.to_i
  end

  def plan_month_cycle_ended_at
    cycle = trial_not_started_or_in_trial? ? 'none' : plan.read_attribute(:cycle) # strange error in specs when using .cycle

    case cycle
    when 'month'
      plan_cycle_ended_at
    when 'year'
      (plan_cycle_started_at + (months_since(plan_cycle_started_at) + 1).months - 1.day).end_of_day
    when 'none'
      Time.now.utc.end_of_day
    end
  end

  def plan_month_cycle_end_time
    plan_month_cycle_ended_at.to_i
  end

private

  def self.update_ranks(site_id)
    site  = Site.find(site_id)
    ranks = PageRankr.ranks(site.hostname, :alexa_global, :google)
    site.google_rank = ranks[:google] || 0
    site.alexa_rank  = ranks[:alexa_global]
    site.save
  end

  # before_validation
  def set_user_attributes
    if user && user_attributes.present? && user_attributes.has_key?("current_password")
      self.user.assign_attributes(user_attributes.select { |k,v| k == "current_password" })
    end
  end

  # before_validation
  def set_default_dev_hostnames
    self.dev_hostnames = DEFAULT_DEV_DOMAINS
  end

  # before_validation
  def set_default_badged
    self.badged = in_free_plan?
    true # don't halt the callback chain
  end

  # validate
  def validates_current_password
    return if @skip_password_validation

    if !new_record? && in_paid_plan? && !trial_not_started_or_in_trial? && errors.empty? &&
      ((state_changed? && archived?) || (changes.keys & (Array(self.class.accessible_attributes) - ['plan_id'] + %w[pending_plan_id next_cycle_plan_id])).present?)
      if user.current_password.blank? || !user.valid_password?(user.current_password)
        self.errors.add(:base, :current_password_needed)
      end
    end
  end

  # validate (archived state)
  def prevent_archive_with_non_paid_invoices
    unless archivable?
      self.errors.add(:base, :not_paid_invoices_prevent_archive, :count => invoices.not_paid.count)
    end
  end

  # before_save
  def clear_alerts_sent_at
    self.overusage_notification_sent_at = nil if plan_id_changed?
  end

  # after_create
  def delay_ranks_update
    Site.delay(:priority => 100, :run_at => 30.seconds.from_now).update_ranks(self.id)
  end

  # before_transition :on => :archive
  def set_archived_at
    self.archived_at = Time.now.utc
  end

  # before_transition :on => :archive
  def cancel_open_or_failed_invoices
    invoices.open_or_failed.each do |invoice|
      invoice.cancel
    end
  end

end


# == Schema Information
#
# Table name: sites
#
#  id                                        :integer         not null, primary key
#  user_id                                   :integer
#  hostname                                  :string(255)
#  dev_hostnames                             :string(255)
#  token                                     :string(255)
#  license                                   :string(255)
#  loader                                    :string(255)
#  state                                     :string(255)
#  archived_at                               :datetime
#  created_at                                :datetime
#  updated_at                                :datetime
#  player_mode                               :string(255)     default("stable")
#  google_rank                               :integer
#  alexa_rank                                :integer
#  path                                      :string(255)
#  wildcard                                  :boolean
#  extra_hostnames                           :string(255)
#  plan_id                                   :integer
#  pending_plan_id                           :integer
#  next_cycle_plan_id                        :integer
#  cdn_up_to_date                            :boolean         default(FALSE)
#  first_paid_plan_started_at                :datetime
#  plan_started_at                           :datetime
#  plan_cycle_started_at                     :datetime
#  plan_cycle_ended_at                       :datetime
#  pending_plan_started_at                   :datetime
#  pending_plan_cycle_started_at             :datetime
#  pending_plan_cycle_ended_at               :datetime
#  overusage_notification_sent_at            :datetime
#  first_plan_upgrade_required_alert_sent_at :datetime
#  refunded_at                               :datetime
#  last_30_days_main_video_views             :integer         default(0)
#  last_30_days_extra_video_views            :integer         default(0)
#  last_30_days_dev_video_views              :integer         default(0)
#  trial_started_at                          :datetime
#  badged                                    :boolean
#  last_30_days_invalid_video_views          :integer         default(0)
#  last_30_days_embed_video_views            :integer         default(0)
#  stats_trial_started_at                    :datetime
#
# Indexes
#
#  index_sites_on_created_at                        (created_at)
#  index_sites_on_hostname                          (hostname)
#  index_sites_on_last_30_days_dev_video_views      (last_30_days_dev_video_views)
#  index_sites_on_last_30_days_embed_video_views    (last_30_days_embed_video_views)
#  index_sites_on_last_30_days_extra_video_views    (last_30_days_extra_video_views)
#  index_sites_on_last_30_days_invalid_video_views  (last_30_days_invalid_video_views)
#  index_sites_on_last_30_days_main_video_views     (last_30_days_main_video_views)
#  index_sites_on_plan_id                           (plan_id)
#  index_sites_on_user_id                           (user_id)
#

