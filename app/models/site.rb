require_dependency 'hostname'
require_dependency 'validators/hostname_validator'
require_dependency 'validators/hostname_uniqueness_validator'
require_dependency 'validators/dev_hostnames_validator'
require_dependency 'validators/extra_hostnames_validator'

class Site < ActiveRecord::Base
  include SiteModules::Api
  include SiteModules::Cycle
  include SiteModules::Billing
  include SiteModules::Referrer
  include SiteModules::Scope
  include SiteModules::Template
  include SiteModules::Usage
  include SiteModules::UsageMonitoring

  DEFAULT_DEV_DOMAINS = '127.0.0.1,localhost'
  PLAYER_MODES = %w[dev beta stable]

  # Versioning
  has_paper_trail ignore: [
    :cdn_up_to_date, :license, :loader, :last_30_days_main_video_views,
    :last_30_days_extra_video_views, :last_30_days_dev_video_views,
    :last_30_days_invalid_video_views, :last_30_days_embed_video_views,
    :last_30_days_billable_video_views_array, :last_30_days_video_tags
  ],
  class_name: 'SiteVersion'

  acts_as_taggable

  attr_accessor :loader_needs_update, :license_needs_update
  attr_accessor :user_attributes, :last_transaction, :remote_ip

  attr_accessible :hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard,
                  :badged, :plan_id, :user_attributes, :remote_ip

  serialize :last_30_days_billable_video_views_array, Array

  uniquify :token, chars: Array('a'..'z') + Array('0'..'9')

  mount_uploader :license, LicenseUploader
  mount_uploader :loader, LoaderUploader

  delegate :name, to: :plan, prefix: true
  delegate :stats_retention_days, to: :plan, prefix: true
  delegate :video_views, to: :plan, prefix: true

  # ================
  # = Associations =
  # ================

  belongs_to :user, validate: true, autosave: true

  # Plans
  belongs_to :plan
  belongs_to :next_cycle_plan, class_name: "Plan"
  belongs_to :pending_plan,    class_name: "Plan"

  # Invoices
  has_many :invoices, class_name: "::Invoice"
  has_one  :last_invoice, class_name: "::Invoice", order: 'created_at DESC'

  # Bundles
  has_many :bundleships,
    class_name: 'Player::Bundleship',
    dependent: :destroy
  has_many :bundles, through: :bundleships

  # Mongoid associations
  def usages
    SiteUsage.where(site_id: id)
  end
  def referrers
    ::Referrer.where(token: token)
  end
  def day_stats
    Stat::Site::Day.where(t: token)
  end
  def video_tags
    VideoTag.where(st: token)
  end

  # ===============
  # = Validations =
  # ===============

  validates :user,        presence: true
  validates :plan,        presence: { message: "Please choose a plan" }, unless: :pending_plan_id?
  validates :player_mode, inclusion: PLAYER_MODES

  validates :hostname,        presence: { if: proc { |s| s.in_or_will_be_in_paid_plan? } }, hostname: true, hostname_uniqueness: true
  validates :dev_hostnames,   dev_hostnames: true
  validates :extra_hostnames, extra_hostnames: true
  validates :path, length: { maximum: 255 }

  validate  :validates_current_password

  # =============
  # = Callbacks =
  # =============

  before_validation :set_user_attributes
  before_validation :set_default_dev_hostnames, unless: :dev_hostnames?

  before_save :set_default_badged, if: proc { |s| s.badged.nil? || s.in_free_plan? }
  before_save :prepare_cdn_update # in site_modules/templates
  before_save :clear_alerts_sent_at
  before_save :prepare_pending_attributes, if: proc { |s| s.pending_plan_id_changed? && s.pending_plan_id? } # in site_modules/cycle
  before_save :set_first_paid_plan_started_at # in site_modules/billing

  after_create :delay_ranks_update, :update_last_30_days_video_views_counters # in site_modules/usage

  after_save :create_and_charge_invoice # in site_modules/billing
  after_save :send_trial_started_email, if: proc { |s| s.plan_id_changed? && s.in_trial_plan? } # in site_modules/billing
  after_save :execute_cdn_update # in site_modules/templates

  # =================
  # = State Machine =
  # =================

  state_machine initial: :active do
    event(:archive)   { transition [:active, :suspended] => :archived }
    event(:suspend)   { transition active: :suspended }
    event(:unsuspend) { transition suspended: :active }

    before_transition on: :archive, do: [:set_archived_at]
    after_transition  on: :archive, do: [:cancel_not_paid_invoices]

    after_transition  to: [:suspended, :archived], do: :delay_remove_loader_and_license # in site/templates
    # after_transition  to: [:suspended, :archived] do |site|
    #   Player::Settings.delay.delete!(site.id)
    # end
  end

  # =================
  # = Class Methods =
  # =================

  def self.to_backbone_json
    all.map(&:to_backbone_json)
  end

  # ====================
  # = Instance Methods =
  # ====================

  def to_backbone_json(options={})
    to_json(
      only: [:token, :hostname],
      methods: [:trial_start_time, :plan_name, :plan_video_views, :plan_month_cycle_start_time, :plan_month_cycle_end_time, :plan_stats_retention_days]
    )
  end

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
      return unless new_plan.trial_plan? || new_plan.standard_plan? || new_plan.free_plan?
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
          if first_paid_plan_started_at?
            write_attribute(:next_cycle_plan_id, new_plan.id)
          else
            write_attribute(:pending_plan_id, new_plan.id)
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
    skip_password(:save!)
  end

  def to_param
    token
  end

  def hostname_with_path_needed
    unless path?
      list = %w[web.me.com web.mac.com homepage.mac.com cargocollective.com]
      list.detect { |h| h == hostname || (extra_hostnames.present? && extra_hostnames.split(/,\s*/).include?(h)) }
    end
  end

  def hostname_with_subdomain_needed
    if wildcard?
      list = %w[tumblr.com squarespace.com posterous.com blogspot.com typepad.com]
      list.detect { |h| h == hostname || (extra_hostnames.present? && extra_hostnames.split(/,\s*/).include?(h)) }
    end
  end

  def hostname_or_token(prefix = '#')
    hostname.presence || "#{prefix}#{token}"
  end

  # Boolean helpers
  def need_path?
    hostname_with_path_needed.present?
  end

  def need_subdomain?
    hostname_with_subdomain_needed.present?
  end

  def created_during_deal?(deal)
    created_at? && (created_at >= deal.started_at && created_at <= deal.ended_at)
  end

  def recommended_plan_name
    if in_paid_plan?
      usages = last_30_days_billable_usages
      name = nil
      if usages.size >= 5
        Plan.standard_plans.order{ video_views.desc }.each do |tested_plan|
          if usages.sum < tested_plan.video_views && usages.mean < tested_plan.daily_video_views
            name = plan.video_views < tested_plan.video_views ? tested_plan.name : nil
          end
        end

        if name.nil? && !in_custom_plan?
          biggest_standard_plan = Plan.standard_plans.order{ video_views.desc }.first
          name = "custom" if usages.sum >= biggest_standard_plan.video_views || usages.mean >= biggest_standard_plan.daily_video_views
        end
      end
      name
    end
    @recommended_plan_name ||= name
  end

  def skip_password(*args)
    action = args.shift
    @skip_password_validation = true
    result = self.send(action, *args)
    @skip_password_validation = false
    result
  end

  def trial_start_time
    trial_started_at.to_i
  end

  def unmemoize_all
    @recommended_plan_name = nil
    unmemoize_all_usages
  end

private

  # after_create
  def self.update_ranks(site_id)
    site = Site.find(site_id)
    begin
      ranks = PageRankr.ranks("http://#{site.hostname}", :alexa_global, :google)
      site.google_rank = ranks[:google] || 0
      site.alexa_rank  = ranks[:alexa_global]
    rescue
      site.google_rank = 0
      site.alexa_rank  = 0
    end
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
    self.badged = true
  end

  # validate
  def validates_current_password
    return true if @skip_password_validation

    if persisted? && in_paid_plan? && errors.empty? &&
      ((state_changed? && archived?) || (changes.keys & (Array(self.class.accessible_attributes) - ['plan_id'] + %w[pending_plan_id next_cycle_plan_id])).present?)
      if user.current_password.blank? || !user.valid_password?(user.current_password)
        self.errors.add(:base, :current_password_needed)
      end
    end
  end

  # before_save
  def clear_alerts_sent_at
    self.overusage_notification_sent_at = nil if plan_id_changed?
  end

  # after_create
  def delay_ranks_update
    Site.delay(priority: 100, run_at: 30.seconds.from_now).update_ranks(id)
  end

  # before_transition on: :archive
  def set_archived_at
    self.archived_at = Time.now.utc
  end

  # before_transition on: :archive
  def cancel_not_paid_invoices
    invoices.not_paid.map(&:cancel)
  end

end

# == Schema Information
#
# Table name: sites
#
#  alexa_rank                                :integer
#  archived_at                               :datetime
#  badged                                    :boolean
#  cdn_up_to_date                            :boolean          default(FALSE)
#  created_at                                :datetime         not null
#  dev_hostnames                             :text
#  extra_hostnames                           :text
#  first_billable_plays_at                   :datetime
#  first_paid_plan_started_at                :datetime
#  first_plan_upgrade_required_alert_sent_at :datetime
#  google_rank                               :integer
#  hostname                                  :string(255)
#  id                                        :integer          not null, primary key
#  last_30_days_billable_video_views_array   :text
#  last_30_days_dev_video_views              :integer          default(0)
#  last_30_days_embed_video_views            :integer          default(0)
#  last_30_days_extra_video_views            :integer          default(0)
#  last_30_days_invalid_video_views          :integer          default(0)
#  last_30_days_main_video_views             :integer          default(0)
#  last_30_days_video_tags                   :integer          default(0)
#  license                                   :string(255)
#  loader                                    :string(255)
#  next_cycle_plan_id                        :integer
#  overusage_notification_sent_at            :datetime
#  path                                      :string(255)
#  pending_plan_cycle_ended_at               :datetime
#  pending_plan_cycle_started_at             :datetime
#  pending_plan_id                           :integer
#  pending_plan_started_at                   :datetime
#  plan_cycle_ended_at                       :datetime
#  plan_cycle_started_at                     :datetime
#  plan_id                                   :integer
#  plan_started_at                           :datetime
#  player_mode                               :string(255)      default("stable")
#  refunded_at                               :datetime
#  settings_updated_at                       :datetime
#  state                                     :string(255)
#  token                                     :string(255)
#  trial_started_at                          :datetime
#  updated_at                                :datetime         not null
#  user_id                                   :integer
#  wildcard                                  :boolean
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

