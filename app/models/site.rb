class Site < ActiveRecord::Base

  DEFAULT_DEV_DOMAINS = '127.0.0.1, localhost'
  PLAYER_MODES = %w[dev beta stable]

  # Versioning
  has_paper_trail

  attr_accessor :user_attributes

  attr_accessible :hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :plan_id, :user_attributes

  uniquify :token, :chars => Array('a'..'z') + Array('0'..'9')

  mount_uploader :license, LicenseUploader
  mount_uploader :loader, LoaderUploader

  # ================
  # = Associations =
  # ================

  belongs_to :user, :validate => true, :autosave => true
  belongs_to :plan
  belongs_to :next_cycle_plan, :class_name => "Plan"

  has_many :invoices
  has_many :invoice_items, :through => :invoices

  # Mongoid associations
  def usages
    SiteUsage.where(:site_id => id)
  end
  def referrers
    Referrer.where(:site_id => id)
  end

  # ==========
  # = Scopes =
  # ==========

  # billing
  scope :billable,      lambda { active.where({ :plan_id.not_in => Plan.where(:name => %w[beta dev]).map(&:id) }, { :next_cycle_plan_id => nil } | { :next_cycle_plan_id.ne => Plan.dev_plan.id }) }
  scope :not_billable,  lambda { where({ :state.ne => 'active' } | ({ :state => 'active' } & ({ :plan_id.in => Plan.where(:name => %w[beta dev]).map(&:id), :next_cycle_plan_id => nil } | { :next_cycle_plan_id => Plan.dev_plan }))) }
  scope :to_be_renewed, lambda { where(:paid_plan_cycle_ended_at.lt => Time.now.utc) }

  # usage_alert scopes
  scope :plan_player_hits_reached_alerted_this_month,                where(:plan_player_hits_reached_alert_sent_at.gte => Time.now.utc.beginning_of_month)
  scope :plan_player_hits_reached_not_alerted_this_month,            where({ :plan_player_hits_reached_alert_sent_at.lt => Time.now.utc.beginning_of_month } | { :plan_player_hits_reached_alert_sent_at => nil })

  # filter
  scope :beta,                 lambda { joins(:plan).where(:plan => { :name => "beta" }) }
  scope :dev,                  lambda { joins(:plan).where(:plan => { :name => "dev" }) }
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
  validates :plan,        :presence => { :message => "Please choose a plan" }
  validates :player_mode, :inclusion => { :in => PLAYER_MODES }

  validates :hostname,        :presence => { :if => :in_paid_plan? }, :hostname => true, :hostname_uniqueness => true
  validates :extra_hostnames, :extra_hostnames => true
  validates :dev_hostnames,   :dev_hostnames => true

  validate  :at_least_one_domain_set, :if => :in_dev_plan?
  validate  :verify_presence_of_credit_card, :unless => :in_dev_plan?
  validate  :validates_current_password

  # =============
  # = Callbacks =
  # =============

  before_validation :set_user_attributes

  before_save :prepare_cdn_update, :clear_alerts_sent_at
  before_save :reset_paid_plan_initially_started_at, :update_for_next_cycle, :if => :plan_id_changed?

  after_save :execute_cdn_update

  after_create :delay_ranks_update

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :active do
    state :pending # Temporary, used in the master branch

    event(:archive)   { transition :active => :archived }
    event(:suspend)   { transition :active => :suspended }
    event(:unsuspend) { transition :suspended => :active }

    before_transition :on => :archive,  :do => :set_archived_at

    after_transition  :to => [:suspended, :archived], :do => :delay_remove_loader_and_license
  end

  # =================
  # = Class Methods =
  # =================

  # delayed method
  def self.update_loader_and_license(site_id, options = {})
    site = Site.find(site_id)
    transaction do
      begin
        if options[:loader]
          purge_loader = site.loader.present?
          site.set_template("loader")
          site.purge_template("loader") if purge_loader
        end
        if options[:license]
          purge_license = site.license.present?
          site.set_template("license")
          site.purge_template("license") if purge_license
        end
        site.cdn_up_to_date = true
        site.save!
      rescue => ex
        Notify.send(ex.message, :exception => ex)
      end
    end
  end

  # delayed method
  def self.update_ranks(site_id)
    site  = Site.find(site_id)
    ranks = PageRankr.ranks(site.hostname)
    site.google_rank = ranks[:google]
    site.alexa_rank  = ranks[:alexa][:global] # [:us] if also returned
    site.save!
  end

  # delayed method
  def self.remove_loader_and_license(site_id)
    site = Site.find(site_id)
    transaction do
      begin
        site.remove_loader, site.remove_license = true, true
        site.cdn_up_to_date = false
        %w[loader license].each { |template| site.purge_template(template) }
        site.save!
      rescue => ex
        Notify.send(ex.message, :exception => ex)
      end
    end
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

  def self.referrer_match_hostname?(referrer, hostname, path = '', wildcard = false)
    referrer = URI.parse(referrer)
    if path || wildcard
      (referrer.host =~ /^(#{wildcard ? '.*' : 'www'}\.)?#{hostname}$/) && (path.blank? || referrer.path =~ %r{^/#{path}.*$})
    else
      referrer.host =~ /^(www\.)?#{hostname}$/
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
    write_attribute :path, attribute.sub('/', '')
  end

  def to_param
    token
  end

  def in_dev_plan?
    plan_id? && plan.dev_plan?
  end

  def in_beta_plan?
    plan_id? && plan.beta_plan?
  end

  def in_paid_plan?
    plan_id? && plan.paid_plan?
  end

  def plan_player_hits_reached_alerted_this_month?
    (Time.now.utc.beginning_of_month..Time.now.utc.end_of_month).cover?(plan_player_hits_reached_alert_sent_at)
  end

  def need_path?
    %w[web.me.com homepage.mac.com].include?(hostname) && path.blank?
  end

  def settings_changed?
    (changed & %w[hostname extra_hostnames dev_hostnames path wildcard]).present?
  end

  def referrer_type(referrer, timestamp = Time.now.utc)
    past_site = version_at(timestamp)
    if past_site.main_referrer?(referrer)
      "main"
    elsif past_site.extra_referrer?(referrer)
      "extra"
    elsif past_site.dev_referrer?(referrer)
      "dev"
    else
      "invalid"
    end
  rescue => ex
    Notify.send("Referrer type could not be guessed: #{ex.message}", :exception => ex)
    "invalid"
  end

  def template_hostnames
    hostnames = []
    unless in_dev_plan?
      hostnames << hostname if hostname.present?
      hostnames += extra_hostnames.split(', ') if extra_hostnames.present?
      hostnames << "path:#{path}" if path.present?
      hostnames << "wildcard:#{wildcard.to_s}" if wildcard.present?
    end
    hostnames += dev_hostnames.split(', ') if dev_hostnames.present?
    hostnames.map! { |hostname| "'#{hostname}'" }
    hostnames.join(',')
  end

  def set_template(name)
    template = ERB.new(File.new(Rails.root.join("app/templates/sites/#{name}.js.erb")).read)

    tempfile = Tempfile.new(name, "#{Rails.root}/tmp")
    tempfile.print template.result(binding)
    tempfile.flush

    self.send("#{name}=", tempfile)
  end

  def purge_template(name)
    mapping = { :loader => 'js', :license => 'l' }
    raise "Unknown template name!" unless mapping.keys.include?(name.to_sym)
    VoxcastCDN.purge("/#{mapping[name.to_sym]}/#{token}.js")
  end

  def set_template(name)
    template = ERB.new(File.new(Rails.root.join("app/templates/sites/#{name}.js.erb")).read)

    tempfile = Tempfile.new(name, "#{Rails.root}/tmp")
    tempfile.print template.result(binding)
    tempfile.flush

    self.send("#{name}=", tempfile)
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

  def current_billable_usage
    @current_billable_usage ||= usages.between(paid_plan_cycle_started_at, paid_plan_cycle_ended_at).to_a.sum do |su|
      su.main_player_hits + su.main_player_hits_cached + su.extra_player_hits + su.extra_player_hits_cached
    end
  end

  def current_percentage_of_plan_used
    if plan.player_hits > 0
      [(current_billable_usage / plan.player_hits.to_f).round(2), 1].min
    else
      0
    end
  end

  def main_referrer?(referrer)
    self.class.referrer_match_hostname?(referrer, hostname, path, wildcard)
  end

  def extra_referrer?(referrer)
    extra_hostnames.split(', ').any? { |h| self.class.referrer_match_hostname?(referrer, h, path, wildcard) }
  end

  def dev_referrer?(referrer)
    dev_hostnames.split(', ').any? { |h| self.class.referrer_match_hostname?(referrer, h, '', wildcard) }
  end

  # before_save :if => :plan_id_changed?
  def reset_paid_plan_initially_started_at
    self.paid_plan_initially_started_at = paid_plan_cycle_ended_at ? paid_plan_cycle_ended_at.tomorrow.midnight : Time.now.utc.midnight
  end

  # before_save :if => :plan_id_changed?
  def update_for_next_cycle
    if (plan.paid_plan? || next_cycle_plan) && (paid_plan_cycle_ended_at.nil? || paid_plan_cycle_ended_at < Time.now.utc)
      new_plan = next_cycle_plan || plan

      if new_plan.dev_plan?
        self.paid_plan_cycle_started_at = nil
        self.paid_plan_cycle_ended_at   = nil
      else
        self.paid_plan_cycle_started_at = if paid_plan_cycle_ended_at
          paid_plan_cycle_ended_at.tomorrow.midnight
        else
          paid_plan_initially_started_at.midnight
        end
        self.paid_plan_cycle_ended_at = (paid_plan_initially_started_at + advance_for_next_cycle_end(new_plan)).end_of_day
      end
      self.plan            = new_plan
      self.next_cycle_plan = nil
    end
    true # don't block the callbacks chain
  end

private

  # before_validation
  def set_user_attributes
    # for user cc fields & current_password only
    if user && user_attributes.present? && in_or_was_in_paid_plan?
      user.attributes = user_attributes
    end
  end

  # validate
  def at_least_one_domain_set
    if hostname.blank? && dev_hostnames.blank? && extra_hostnames.blank?
      self.errors.add(:base, :at_least_one_domain)
    end
  end

  # validate unless :in_dev_plan?
  def verify_presence_of_credit_card
    if user && !user.cc?
      self.errors.add(:base, :credit_card_needed)
    end
  end

  # validate if in_paid_plan?
  def validates_current_password
    if !new_record? && in_or_was_in_paid_plan? &&
      ((state_changed? && archived?) || (changes.keys & (Array(self.class.accessible_attributes) + ['next_cycle_plan_id'])).present?) &&
      errors.empty?
      if user.current_password.blank? || !user.valid_password?(user.current_password)
        self.errors.add(:base, :current_password_needed)
      end
    end
  end

  # before_save
  def prepare_cdn_update
    @loader_needs_update  = false
    @license_needs_update = false
    common_conditions = new_record? || (state_changed? && active?)

    if common_conditions || player_mode_changed?
      self.cdn_up_to_date  = false
      @loader_needs_update = true
    end

    if common_conditions || settings_changed? || plan_id_changed?
      self.cdn_up_to_date   = false
      @license_needs_update = true
    end
  end

  # before_save
  def clear_alerts_sent_at
    self.plan_player_hits_reached_alert_sent_at = nil if plan_id_changed?
  end

  # after_save
  def execute_cdn_update
    if @loader_needs_update || @license_needs_update
      Site.delay.update_loader_and_license(self.id, :loader => @loader_needs_update, :license => @license_needs_update)
    end
  end

  # after_create
  def delay_ranks_update
    Site.delay(:priority => 100, :run_at => 30.seconds.from_now).update_ranks(self.id)
  end

  # before_transition :on => :archive
  def set_archived_at
    self.archived_at = Time.now.utc
  end

  # after_transition :to => [:suspended, :archived]
  def delay_remove_loader_and_license
    Site.delay.remove_loader_and_license(self.id)
  end

  def months_since_paid_plan_initially_started_at
    now = Time.now.utc
    if paid_plan_initially_started_at && (now - paid_plan_initially_started_at >= 1.month)
      months = now.month - paid_plan_initially_started_at.month
      months -= 1 if months > 0 && (now.day - paid_plan_initially_started_at.day) < 0

      (now.year - paid_plan_initially_started_at.year) * 12 + months
    else
      0
    end
  end

  def advance_for_next_cycle_end(plan)
    if plan.yearly?
      (months_since_paid_plan_initially_started_at + 12).months
    else
      (months_since_paid_plan_initially_started_at + 1).months
    end - 1.day
  end

  def in_or_was_in_paid_plan?
    plan_id? && ((plan_id_changed? && !Plan.find(plan_id_was).dev_plan?) || (!plan_id_changed? && plan.paid_plan?))
  end

end



# == Schema Information
#
# Table name: sites
#
#  id                                         :integer         not null, primary key
#  user_id                                    :integer
#  hostname                                   :string(255)
#  dev_hostnames                              :string(255)
#  token                                      :string(255)
#  license                                    :string(255)
#  loader                                     :string(255)
#  state                                      :string(255)
#  archived_at                                :datetime
#  created_at                                 :datetime
#  updated_at                                 :datetime
#  player_mode                                :string(255)     default("stable")
#  google_rank                                :integer
#  alexa_rank                                 :integer
#  path                                       :string(255)
#  wildcard                                   :boolean
#  extra_hostnames                            :string(255)
#  plan_id                                    :integer
#  cdn_up_to_date                             :boolean
#  paid_plan_initially_started_at             :datetime
#  paid_plan_cycle_started_at                 :datetime
#  paid_plan_cycle_ended_at                   :datetime
#  next_cycle_plan_id                         :integer
#  plan_player_hits_reached_alert_sent_at     :datetime
#  last_30_days_main_player_hits_total_count  :integer         default(0)
#  last_30_days_extra_player_hits_total_count :integer         default(0)
#  last_30_days_dev_player_hits_total_count   :integer         default(0)
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

