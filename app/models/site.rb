class Site < ActiveRecord::Base
  extend ActiveSupport::Memoizable
  require 'site/invoice'
  require 'site/referrer'
  require 'site/templates'

  DEFAULT_DEV_DOMAINS = '127.0.0.1, localhost'
  PLAYER_MODES = %w[dev beta stable]

  # Versioning
  has_paper_trail

  attr_accessor :loader_needs_update, :license_needs_update
  attr_accessor :user_attributes, :charging_options, :transaction

  attr_accessible :hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :plan_id, :user_attributes

  uniquify :token, :chars => Array('a'..'z') + Array('0'..'9')

  mount_uploader :license, LicenseUploader
  mount_uploader :loader, LoaderUploader

  delegate :name, :to => :plan, :prefix => true

  # ================
  # = Associations =
  # ================

  belongs_to :user, :validate => true, :autosave => true
  belongs_to :plan
  belongs_to :next_cycle_plan, :class_name => "Plan"
  belongs_to :pending_plan,    :class_name => "Plan"

  has_many :invoices, :class_name => "::Invoice"
  has_one  :last_invoice, :class_name => "::Invoice", :order => :created_at.desc
  has_one  :last_paid_invoice, :class_name => "::Invoice", :conditions => { :state => 'paid' }, :order => :created_at.desc

  # Mongoid associations
  def usages
    SiteUsage.where(:site_id => id)
  end
  def referrers
    ::Referrer.where(:site_id => id)
  end

  # ==========
  # = Scopes =
  # ==========

  # billing
  scope :billable,      lambda { active.where({ :plan_id.in => Plan.paid_plans.map(&:id) }, { :next_cycle_plan_id => nil } | { :next_cycle_plan_id.ne => Plan.dev_plan.id }) }
  scope :not_billable,  lambda { where({ :state.ne => 'active' } | ({ :state => 'active' } & ({ :plan_id.in => Plan.free_plans.map(&:id), :next_cycle_plan_id => nil } | { :next_cycle_plan_id => Plan.dev_plan }))) }
  scope :to_be_renewed, lambda { where(:plan_cycle_ended_at.lt => Time.now.utc, :pending_plan_id => nil) }
  scope :refundable,    lambda { where(:first_paid_plan_started_at.gte => 30.days.ago, :refunded_at => nil) }
  scope :refunded,      lambda { where(:state => 'archived', :refunded_at.ne => nil) }

  scope :in_paid_plan, lambda { joins(:plan).merge(Plan.paid_plans) }

  # usage_monitoring scopes
  scope :plan_player_hits_reached_notified, where(:plan_player_hits_reached_notification_sent_at.ne => nil)

  # filter
  scope :beta,                 joins(:plan).where(:plan => { :name => "beta" })
  scope :dev,                  joins(:plan).where(:plan => { :name => "dev" })
  scope :sponsored,            joins(:plan).where(:plan => { :name => "sponsored" })
  scope :custom,               joins(:plan).where(:plan => { :name.matches => "custom%" })
  scope :active,               where(:state => 'active')
  scope :suspended,            where(:state => 'suspended')
  scope :archived,             where(:state => 'archived')
  scope :not_archived,         where(:state.ne => 'archived')
  scope :with_wildcard,        where(:wildcard => true)
  scope :with_path,            where({ :path.ne => nil } & { :path.ne => '' })
  scope :with_extra_hostnames, where({ :extra_hostnames.ne => nil } & { :extra_hostnames.ne => '' })

  # admin
  scope :user_id,         lambda { |user_id| where(user_id: user_id) }
  scope :created_between, lambda { |start_date, end_date| where(:created_at.gte => start_date, :created_at.lt => end_date) }

  # sort
  scope :by_hostname,    lambda { |way = 'asc'| order(:hostname.send(way)) }
  scope :by_user,        lambda { |way = 'desc'| includes(:user).order(:users => [:first_name.send(way), :email.send(way)]) }
  scope :by_state,       lambda { |way = 'desc'| order(:state.send(way)) }
  scope :by_plan_price,  lambda { |way = 'desc'| includes(:plan).order(:plans => :price.send(way)) }
  scope :by_google_rank, lambda { |way = 'desc'| where(:google_rank.gte => 0).order(:google_rank.send(way)) }
  scope :by_alexa_rank,  lambda { |way = 'desc'| where(:alexa_rank.gte => 1).order(:alexa_rank.send(way)) }
  scope :by_date,        lambda { |way = 'desc'| order(:created_at.send(way)) }
  scope :by_last_30_days_billable_player_hits_total_count, lambda { |way = 'desc'|
    order("(sites.last_30_days_main_player_hits_total_count + sites.last_30_days_extra_player_hits_total_count) #{way}")
  }
  scope :by_last_30_days_extra_player_hits_total_percentage, lambda { |way = 'desc'|
    order("CASE WHEN (sites.last_30_days_main_player_hits_total_count + sites.last_30_days_extra_player_hits_total_count) > 0
    THEN (sites.last_30_days_extra_player_hits_total_count / CAST(sites.last_30_days_main_player_hits_total_count + sites.last_30_days_extra_player_hits_total_count AS DECIMAL))
    ELSE -1 END #{way}")
  }
  scope :by_last_30_days_plan_usage_persentage, lambda { |way = 'desc'|
    includes(:plan).
    order("CASE WHEN (sites.plan_id IS NOT NULL AND plans.player_hits > 0)
    THEN ((sites.last_30_days_main_player_hits_total_count + sites.last_30_days_extra_player_hits_total_count) / CAST(plans.player_hits AS DECIMAL))
    ELSE -1 END #{way}")
  }

  # search
  def self.search(q)
    joins(:user).
    where(:lower.func(:email).matches % :lower.func("%#{q}%") |
          :lower.func(:first_name).matches % :lower.func("%#{q}%") |
          :lower.func(:last_name).matches % :lower.func("%#{q}%") |
          :lower.func(:hostname).matches % :lower.func("%#{q}%") |
          :lower.func(:dev_hostnames).matches % :lower.func("%#{q}%") |
          :lower.func(:extra_hostnames).matches % :lower.func("%#{q}%"))
  end

  # ===============
  # = Validations =
  # ===============

  validates :user,        :presence => true
  validates :plan,        :presence => { :message => "Please choose a plan" }, :unless => :pending_plan_id?
  validates :player_mode, :inclusion => { :in => PLAYER_MODES }

  validates :hostname,        :presence => { :if => proc { |s| s.in_beta_plan? || s.in_or_will_be_in_paid_plan? } }, :hostname => true, :hostname_uniqueness => true
  validates :extra_hostnames, :extra_hostnames => true
  validates :dev_hostnames,   :dev_hostnames => true

  validate  :verify_presence_of_credit_card, :if => :in_or_will_be_in_paid_plan?
  validate  :validates_current_password

  # =============
  # = Callbacks =
  # =============

  before_validation :set_user_attributes
  before_validation :set_default_dev_hostnames, :unless => :dev_hostnames?

  before_save :prepare_cdn_update # in site/templates
  before_save :clear_alerts_sent_at
  before_save :pend_plan_changes, :if => :pending_plan_id_changed? # in site/invoice
  before_save :set_first_paid_plan_started_at # in site/invoice

  after_save :create_and_charge_invoice # in site/invoice
  after_save :execute_cdn_update # in site/templates

  after_create :delay_ranks_update # in site/templates

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :active do
    state :pending # Temporary, used in the master branch

    event(:archive)   { transition [:active, :suspended] => :archived }
    event(:suspend)   { transition :active => :suspended }
    event(:unsuspend) { transition :suspended => :active }

    before_transition :on => :archive, :do => :set_archived_at # TODO: Cancel invoices that are not paid if site plan has not been activated yet
    # before_transition :on => :unsuspend, :do => :pend_plan_changes # TODO!!

    after_transition  :to => [:suspended, :archived], :do => :delay_remove_loader_and_license  # in site/templates
  end

  # =================
  # = Class Methods =
  # =================

  # delayed method
  def self.update_ranks(site_id)
    site  = Site.find(site_id)
    ranks = PageRankr.ranks(site.hostname)
    site.google_rank = ranks[:google]
    site.alexa_rank  = ranks[:alexa][:global] # [:us] if also returned
    site.save(validate: false) # don't validate for sites that are in_or_will_be_in_paid_plan? but when the user has no credit card (yet)
  end

  # Recurring task
  def self.delay_update_last_30_days_counters_for_not_archived_sites
    unless Delayed::Job.already_delayed?('%Site%update_last_30_days_counters_for_not_archived_sites%')
      delay(:run_at => Time.new.utc.tomorrow.midnight + 1.hour).update_last_30_days_counters_for_not_archived_sites
    end
  end

  def self.update_last_30_days_counters_for_not_archived_sites
    delay_update_last_30_days_counters_for_not_archived_sites
    not_archived.find_each(:batch_size => 100) do |site|
      site.update_last_30_days_counters
    end
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
    write_attribute :path, attribute.downcase.gsub(/^\/|\/$/, '')
  end

  def plan_id=(attribute)
    return if pending_plan_id?

    if attribute.to_s == attribute.to_i.to_s # id passed
      new_plan = Plan.find_by_id(attribute.to_i)
      return unless new_plan.standard_plan? || new_plan.dev_plan? || new_plan.beta_plan?
    else # token passed
      new_plan = Plan.find_by_token(attribute)
    end

    if new_plan.present?
      if plan_id?
        case plan.upgrade?(new_plan)
        when true  # Upgrade
          write_attribute(:pending_plan_id, new_plan.id)
          write_attribute(:next_cycle_plan_id, nil)
        when false # Downgrade
          write_attribute(:next_cycle_plan_id, new_plan.id)
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

  def set_user_attributes
    if user && user_attributes.present?
      if user_attributes.has_key?("current_password")
        self.user.attributes = user_attributes.select { |k,v| k == "current_password" }
      end
    end
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

  def need_path?
    %w[web.me.com web.mac.com homepage.mac.com].include?(hostname) && !path?
  end

  def recommended_plan_name
    usages = current_monthly_billable_usages.select { |u| u > 0 }
    if usages.size >= 5
      if usages.sum < Plan.comet_player_hits && usages.mean < Plan.comet_daily_player_hits
        "comet"
      elsif usages.sum < Plan.planet_player_hits && usages.mean < Plan.planet_daily_player_hits
        "planet"
      elsif usages.sum < Plan.star_player_hits && usages.mean < Plan.star_daily_player_hits
        "star"
      elsif usages.sum < Plan.galaxy_player_hits && usages.mean < Plan.galaxy_daily_player_hits
        "galaxy"
      else
        "custom"
      end
    else
      nil
    end
  end

  def update_last_30_days_counters
    self.last_30_days_main_player_hits_total_count  = 0
    self.last_30_days_extra_player_hits_total_count = 0
    self.last_30_days_dev_player_hits_total_count   = 0
    usages.between(Time.now.utc.midnight - 30.days, Time.now.utc.midnight).all.each do |usage|
      self.last_30_days_main_player_hits_total_count  += usage.main_player_hits + usage.main_player_hits_cached
      self.last_30_days_extra_player_hits_total_count += usage.extra_player_hits + usage.extra_player_hits_cached
      self.last_30_days_dev_player_hits_total_count   += usage.dev_player_hits + usage.dev_player_hits_cached
    end
    self.save
  end

  def current_monthly_billable_usages
    usages.between(plan_month_cycle_started_at, plan_month_cycle_ended_at).map(&:billable_player_hits)
  end
  memoize :current_monthly_billable_usages

  def current_monthly_billable_usages_sum
    current_monthly_billable_usages.sum
  end
  memoize :current_monthly_billable_usages_sum

  def current_percentage_of_plan_used
    if in_paid_plan?
      percentage = [(current_monthly_billable_usages_sum / plan.player_hits.to_f).round(2), 1].min
      percentage == 0.0 && current_monthly_billable_usages_sum > 0 ? 0.01 : percentage
    else
      0
    end
  end

  def plan_month_cycle_started_at
    case plan.read_attribute(:cycle) # strange error in specs when using .cycle
    when 'month'
      plan_cycle_started_at
    when 'year'
      plan_cycle_started_at + months_since(plan_cycle_started_at).months
    when 'none'
      plan_started_at + months_since(plan_started_at).months
    end
  end

  def plan_month_cycle_ended_at
    case plan.read_attribute(:cycle) # strange error in specs when using .cycle
    when 'month'
      plan_cycle_ended_at
    when 'year'
      (plan_cycle_started_at + (months_since(plan_cycle_started_at) + 1).months - 1.day).end_of_day
    when 'none'
      (plan_started_at + (months_since(plan_started_at) + 1).months - 1.day).end_of_day
    end
  end

  def percentage_of_days_over_daily_limit(max_days = 60)
    if in_paid_plan?
      last_days       = [days_since(first_paid_plan_started_at), max_days].min
      over_limit_days = usages.between(last_days.days.ago.utc.midnight, Time.now.utc.midnight).to_a.count { |su| su.billable_player_hits > (plan.player_hits / 30.0) }

      [(over_limit_days / last_days.to_f).round(2), 1].min
    else
      0
    end
  end

private

  # validate if in_or_will_be_in_paid_plan?
  def verify_presence_of_credit_card
    if user && !user.cc? && !user.pending_cc? && !user.any_cc_attrs?
      self.errors.add(:base, :credit_card_needed)
    end
  end

  # validate
  def validates_current_password
    return if @skip_password_validation
    if !new_record? && in_paid_plan? && errors.empty? &&
      ((state_changed? && archived?) || (changes.keys & (Array(self.class.accessible_attributes) - ['plan_id'] + %w[pending_plan_id next_cycle_plan_id])).present?)
      if user.current_password.blank? || !user.valid_password?(user.current_password)
        self.errors.add(:base, :current_password_needed)
      end
    end
  end

  # before_validation
  def set_default_dev_hostnames
    self.dev_hostnames = DEFAULT_DEV_DOMAINS
  end

  # before_save
  def clear_alerts_sent_at
    self.plan_player_hits_reached_notification_sent_at = nil if plan_id_changed?
  end

  # after_create
  def delay_ranks_update
    Site.delay(:priority => 100, :run_at => 30.seconds.from_now).update_ranks(self.id)
  end

  # before_transition :on => :archive
  def set_archived_at
    self.archived_at = Time.now.utc
  end

end



# == Schema Information
#
# Table name: sites
#
#  id                                            :integer         not null, primary key
#  user_id                                       :integer
#  hostname                                      :string(255)
#  dev_hostnames                                 :string(255)
#  token                                         :string(255)
#  license                                       :string(255)
#  loader                                        :string(255)
#  state                                         :string(255)
#  archived_at                                   :datetime
#  created_at                                    :datetime
#  updated_at                                    :datetime
#  player_mode                                   :string(255)     default("stable")
#  google_rank                                   :integer
#  alexa_rank                                    :integer
#  path                                          :string(255)
#  wildcard                                      :boolean
#  extra_hostnames                               :string(255)
#  plan_id                                       :integer
#  pending_plan_id                               :integer
#  next_cycle_plan_id                            :integer
#  cdn_up_to_date                                :boolean
#  first_paid_plan_started_at                    :datetime
#  plan_started_at                               :datetime
#  plan_cycle_started_at                         :datetime
#  plan_cycle_ended_at                           :datetime
#  pending_plan_started_at                       :datetime
#  pending_plan_cycle_started_at                 :datetime
#  pending_plan_cycle_ended_at                   :datetime
#  plan_player_hits_reached_notification_sent_at :datetime
#  first_plan_upgrade_required_alert_sent_at     :datetime
#  last_30_days_main_player_hits_total_count     :integer         default(0)
#  last_30_days_extra_player_hits_total_count    :integer         default(0)
#  last_30_days_dev_player_hits_total_count      :integer         default(0)
#
# Indexes
#
#  index_sites_on_created_at                                  (created_at)
#  index_sites_on_hostname                                    (hostname)
#  index_sites_on_last_30_days_dev_player_hits_total_count    (last_30_days_dev_player_hits_total_count)
#  index_sites_on_last_30_days_extra_player_hits_total_count  (last_30_days_extra_player_hits_total_count)
#  index_sites_on_last_30_days_main_player_hits_total_count   (last_30_days_main_player_hits_total_count)
#  index_sites_on_plan_id                                     (plan_id)
#  index_sites_on_user_id                                     (user_id)
#

