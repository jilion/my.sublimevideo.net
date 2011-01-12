class Site < ActiveRecord::Base

  DEFAULT_DEV_DOMAINS = '127.0.0.1, localhost'
  PLAYER_MODES = %w[dev beta stable]

  # Pagination
  cattr_accessor :per_page
  self.per_page = 50

  # Versioning
  has_paper_trail

  attr_accessor :user_attributes, :addon_ids_was

  attr_accessible :hostname, :dev_hostnames, :extra_hostnames, :path, :wildcard, :plan_id, :addon_ids, :user_attributes

  uniquify :token, :chars => Array('a'..'z') + Array('0'..'9')

  mount_uploader :license, LicenseUploader
  mount_uploader :loader, LoaderUploader

  # ================
  # = Associations =
  # ================

  belongs_to :user, :validate => true, :autosave => true
  belongs_to :plan
  has_many :invoice_items
  has_many :invoices, :through => :invoice_items
  has_and_belongs_to_many :addons
  has_many :lifetimes
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

  scope :billable, lambda { |started_at, ended_at| where({ :activated_at.lte => ended_at }, { :archived_at => nil } | { :archived_at.gte => started_at }) }

  # usage_alert scopes
  scope :plan_player_hits_reached_alerted_this_month, where({ :plan_player_hits_reached_alert_sent_at.gte => Time.now.utc.beginning_of_month })
  scope :plan_player_hits_reached_not_alerted_this_month, where({ :plan_player_hits_reached_alert_sent_at.lt => Time.now.utc.beginning_of_month } | { :plan_player_hits_reached_alert_sent_at => nil })
  scope :next_plan_recommended_alert_sent_at_alerted_this_month, where({ :next_plan_recommended_alert_sent_at.gte => Time.now.utc.beginning_of_month })
  scope :next_plan_recommended_alert_sent_at_not_alerted_this_month, where({ :next_plan_recommended_alert_sent_at.lt => Time.now.utc.beginning_of_month } | { :next_plan_recommended_alert_sent_at => nil })

  # includes
  scope :with_plan,   includes(:plan)
  scope :with_addons, includes(:addons)

  # filter
  scope :beta,          lambda { with_state(:beta) }
  scope :dev,           lambda { with_state(:dev) }
  scope :active,        lambda { with_state(:active) }
  scope :suspended,     lambda { with_state(:suspended) }
  scope :archived,      lambda { with_state(:archived) }
  scope :not_archived,  lambda { without_state(:archived) }
  scope :with_wildcard, where(:wildcard => true)
  scope :with_path,     where({ :path.ne => nil } & { :path.ne => '' })
  scope :with_extra_hostnames, where({ :extra_hostnames.ne => nil } & { :extra_hostnames.ne => '' })
  scope :with_ssl,      joins(:addons).where(:addons => { :name => "ssl" })

  # admin
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
    where(:lower.func(:email).matches % :lower.func("%#{q}%") \
        | :lower.func(:first_name).matches % :lower.func("%#{q}%") \
        | :lower.func(:last_name).matches % :lower.func("%#{q}%") \
        | :lower.func(:hostname).matches % :lower.func("%#{q}%") \
        | :lower.func(:dev_hostnames).matches % :lower.func("%#{q}%") \
        | :lower.func(:extra_hostnames).matches % :lower.func("%#{q}%"))
  end

  # ===============
  # = Validations =
  # ===============

  validates :user,            :presence => true
  validates :hostname,        :hostname_uniqueness => true, :hostname => true
  validates :extra_hostnames, :extra_hostnames => true
  validates :dev_hostnames,   :dev_hostnames => true
  validates :player_mode,     :inclusion => { :in => PLAYER_MODES }
  validate  :at_least_one_domain_set

  # =============
  # = Callbacks =
  # =============

  before_validation :set_user_attributes
  before_save :prepare_cdn_update, :clear_alerts_sent_at
  after_save :execute_cdn_update
  after_create :delay_ranks_update
  # Temporary
  after_update :activate, :if => lambda { |site| site.beta? && site.plan_id? }

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :dev do
    state :pending # Temporary, used in the master branch
    state :beta # Temporary, used in lib/one_time/site.rb and lib/tasks/one_time.rake

    state :dev do
      # TODO: When beta state will be removed, place the following validates for every state
      validates :plan, :presence => { :message => "Please choose a plan" }, :if => :new_record?
    end

    state :active do
      validates :hostname, :presence => true
      # TODO: When beta state will be removed, place the following validates for every state
      validates :plan, :presence => { :message => "Please choose a plan" }
      validate :verify_presence_of_credit_card
    end

    event(:rollback)  { transition :beta => :dev }
    event(:activate)  { transition [:dev, :beta] => :active }
    event(:archive)   { transition [:dev, :beta, :active] => :archived }
    event(:suspend)   { transition :active => :suspended }
    event(:unsuspend) { transition :suspended => :active }

    before_transition :on => :activate, :do => :set_activated_at
    before_transition :on => :archive,  :do => :set_archived_at

    after_transition  :to => [:suspended, :archived], :do => :delay_remove_loader_and_license
  end

  # =================
  # = Class Methods =
  # =================

protected

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

public

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

  def addon_ids=(ids = [])
    @addon_ids_was = addon_ids
    self.addons = Addon.find(ids.reject { |i| i.blank? })
  end

  def to_param
    token
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

  def addon_ids_changed?
    @addon_ids_was && @addon_ids_was != addon_ids
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
    if active? || beta?
      hostnames << hostname if hostname.present?
      hostnames += extra_hostnames.split(', ') if extra_hostnames.present?
      hostnames << "path:#{path}" if path.present?
      hostnames << "wildcard:#{wildcard.to_s}" if wildcard.present?
      hostnames << "addons:#{addons.map { |a| a.name }.sort.join(',')}" if path.present?
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

private

  # before_validation
  def set_user_attributes
    if user && user_attributes.present?
      user.attributes = user_attributes
    end
  end

  # validate
  def at_least_one_domain_set
    if !active? && hostname.blank? && dev_hostnames.blank? && extra_hostnames.blank?
      self.errors.add(:base, :at_least_one_domain)
    end
  end

  # validate on :active
  def verify_presence_of_credit_card
    self.errors.add(:base, :credit_card_needed) unless user.cc?
  end

  # before_save
  def prepare_cdn_update
    @loader_needs_update  = false
    @license_needs_update = false

    if new_record? || player_mode_changed? || (state_changed? && %w[dev active].include?(state))
      self.cdn_up_to_date  = false
      @loader_needs_update = true
    end
    if new_record? || settings_changed? || addon_ids_changed? || (state_changed? && %w[dev active].include?(state))
      self.cdn_up_to_date   = false
      @license_needs_update = true
    end
  end

  # before_save
  def clear_alerts_sent_at
    if plan_id_changed?
      self.plan_player_hits_reached_alert_sent_at = nil
      self.next_plan_recommended_alert_sent_at    = nil
    end
  end

  # after_create
  def delay_ranks_update
    Site.delay(:priority => 100, :run_at => 30.seconds.from_now).update_ranks(self.id)
  end

  # after_save
  def execute_cdn_update
    if @loader_needs_update || @license_needs_update
      Site.delay.update_loader_and_license(self.id, :loader => @loader_needs_update, :license => @license_needs_update)
    end
  end

  # before_transition :on => :activate
  def set_activated_at
    self.activated_at = Time.now.utc
  end

  # before_transition :on => :archive
  def set_archived_at
    self.archived_at = Time.now.utc
  end

  # after_transition :to => [:suspended, :archived]
  def delay_remove_loader_and_license
    Site.delay.remove_loader_and_license(self.id)
  end

  # ===================
  # = Utility Methods =
  # ===================

protected

  def self.referrer_match_hostname?(referrer, hostname, path = '', wildcard = false)
    referrer = URI.parse(referrer)
    if path || wildcard
      (referrer.host =~ /^(#{wildcard ? '.*' : 'www'}\.)?#{hostname}$/) && (path.blank? || referrer.path =~ %r{^/#{path}.*$})
    else
      referrer.host =~ /^(www\.)?#{hostname}$/
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
#  activated_at                               :datetime
#  plan_player_hits_reached_alert_sent_at     :datetime
#  next_plan_recommended_alert_sent_at        :datetime
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

