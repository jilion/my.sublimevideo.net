class Site < ActiveRecord::Base
  
  DEFAULT_DEV_DOMAINS = '127.0.0.1, localhost'
  PLAYER_MODES = %w[dev beta stable]
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 100
  
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
  
  scope :with_plan,   includes(:plan)
  scope :with_addons, includes(:addons)
  
  scope :archived,     where(:state => 'archived')
  scope :not_archived, where(:state.not_eq => 'archived')
  
  scope :by_hostname,    lambda { |way = 'asc'| order("#{Site.quoted_table_name}.hostname #{way}") }
  scope :by_user,        lambda { |way = 'desc'| includes(:user).order("#{User.quoted_table_name}.first_name #{way}, #{User.quoted_table_name}.email #{way}") }
  scope :by_state,       lambda { |way = 'desc'| order("#{Site.quoted_table_name}.state #{way}") }
  scope :by_google_rank, lambda { |way = 'desc'| where(:google_rank.gte => 0).order("#{Site.quoted_table_name}.google_rank #{way}") }
  scope :by_alexa_rank,  lambda { |way = 'desc'| where(:alexa_rank.gte => 1).order("#{Site.quoted_table_name}.alexa_rank #{way}") }
  scope :by_date,        lambda { |way = 'desc'| order("#{Site.quoted_table_name}.created_at #{way}") }
  scope :search,         lambda { |q| includes(:user).where(["LOWER(#{Site.quoted_table_name}.hostname) LIKE LOWER(?) OR LOWER(#{Site.quoted_table_name}.dev_hostnames) LIKE LOWER(?) OR LOWER(#{User.quoted_table_name}.email) LIKE LOWER(?) OR LOWER(#{User.quoted_table_name}.first_name) LIKE LOWER(?) OR LOWER(#{User.quoted_table_name}.last_name) LIKE LOWER(?)", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"]) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,            :presence => true
  validates :plan,            :presence => { :message => "Please choose a plan" }
  validates :hostname,        :hostname_uniqueness => true, :hostname => true
  validates :extra_hostnames, :extra_hostnames => true
  validates :dev_hostnames,   :dev_hostnames => true
  validates :player_mode,     :inclusion => { :in => PLAYER_MODES }
  validate  :at_least_one_domain_set
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_user_attributes
  before_save :prepare_cdn_update
  after_create :delay_ranks_update
  after_save :execute_cdn_update
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :dev do
    before_transition :to => :dev,      :do => :set_cdn_up_to_date_to_false
    before_transition :on => :activate, :do => :set_activated_at
    before_transition :on => :archive,  :do => :set_archived_at
    
    after_transition  :to => [:archived, :suspended], :do => :delay_remove_loader_and_license
    
    event(:activate)   { transition :dev => :active }
    event(:archive)    { transition [:dev, :active] => :archived }
    event(:suspend)    { transition :active => :suspended }
    event(:unsuspend)  { transition :suspended => :active }
    
    state :beta # Pending, using in lib/one_time/site.rb
    
    state :active do
      validates_presence_of :hostname
    end
  end
  
  # =================
  # = Class Methods =
  # =================
  
protected
  
  class << self
    def referrer_match_hostname?(referrer, hostname, path = '', wildcard = false)
      if path || wildcard
        referrer =~ /^.+:\/\/(#{wildcard ? '.*' : 'www'}\.)?#{hostname}#{"(\:[0-9]+)?\/#{path}" if path.present?}.*$/
      else
        URI.parse(referrer).host =~ /^(www\.)?#{hostname}$/
      end
    end
    
    # delayed method
    def update_loader_and_license(id, options = {})
      site = Site.find(id)
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
    def update_ranks(id)
      site = Site.find(id)
      ranks = PageRankr.ranks(site.hostname)
      site.google_rank = ranks[:google]
      site.alexa_rank  = ranks[:alexa]
      site.save!
    end
    
    # delayed method
    def remove_loader_and_license(id)
      site = Site.find(id)
      transaction do
        begin
          site.remove_loader  = true
          site.remove_license = true
          site.cdn_up_to_date = false
          site.purge_template("loader")
          site.purge_template("license")
          site.save!
        rescue => ex
          Notify.send(ex.message, :exception => ex)
        end
      end
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
  
  def template_hostnames
    hostnames = []
    if active?
      hostnames << hostname if hostname.present?
      hostnames += extra_hostnames.split(', ') if extra_hostnames.present?
      hostnames << "path:#{path}" if path.present?
      hostnames << "wildcard:#{wildcard.to_s}" if wildcard.present?
      hostnames << "addons:#{addons.map { |a| a.name }.sort.join(',')}" if path.present?
    end
    hostnames += dev_hostnames.split(', ') if dev_hostnames.present?
    hostnames.map! { |hostname| "'" + hostname + "'" }
    hostnames.join(',')
  end
  
  def need_path?
    %w[web.me.com homepage.mac.com].include?(hostname) && path.blank?
  end
  
  def referrer_type(referrer, timestamp = Time.now.utc)
    past_site = version_at(timestamp)
    if main_referrer?(referrer, past_site)
      "main"
    elsif extra_referrer?(referrer, past_site, past_site.extra_hostnames.split(', '))
      "extra"
    elsif dev_referrer?(referrer, past_site, past_site.dev_hostnames.split(', '))
      "dev"
    else
      "invalid"
    end
  rescue
    "invalid"
  end
  
  def settings_changed?
    (changed & %w[hostname extra_hostnames dev_hostnames path wildcard]).present?
  end
  
  def addons_changed?
    @addon_ids_was && @addon_ids_was != addon_ids
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
  
protected
  
  # before_validation
  def set_user_attributes
    if user && user_attributes.present?
      user.attributes = user_attributes
    end
  end
  
  # validate
  def at_least_one_domain_set
    unless active? || hostname.present? || dev_hostnames.present? || extra_hostnames.present?
      errors[:base] << "Please set at least a development or an extra domain"
    end
  end
  
  # before_save
  def prepare_cdn_update
    if new_record? || player_mode_changed? # loader
      set_cdn_up_to_date_to_false
      @loader_needs_update = true
    end
    
    if new_record? || settings_changed? || addons_changed? || (state_changed? && %w[dev active].include?(state))
      set_cdn_up_to_date_to_false
      @license_needs_update = true
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
  
  # before_transition :to => :dev
  def set_cdn_up_to_date_to_false
    self.cdn_up_to_date = false
  end
  
  # before_transition :on => :activate
  def set_activated_at
    self.activated_at = Time.now.utc
  end
  
  # before_transition :on => :archive
  def set_archived_at
    self.archived_at = Time.now.utc
  end
  
  # after_transition :to => [:archived, :suspended]
  def delay_remove_loader_and_license
    Site.delay.remove_loader_and_license(self.id)
  end
  
  def main_referrer?(referrer, past_site)
    self.class.referrer_match_hostname?(referrer, past_site.hostname, past_site.path, past_site.wildcard)
  end
  
  def extra_referrer?(referrer, past_site, past_hosts)
    past_hosts.any? { |h| self.class.referrer_match_hostname?(referrer, h, past_site.path, past_site.wildcard) }
  end
  
  def dev_referrer?(referrer, past_site, past_hosts)
    past_hosts.any? { |h| self.class.referrer_match_hostname?(referrer, h, '', past_site.wildcard) }
  end
  
end



# == Schema Information
#
# Table name: sites
#
#  id                    :integer         not null, primary key
#  user_id               :integer
#  hostname              :string(255)
#  dev_hostnames         :string(255)
#  token                 :string(255)
#  license               :string(255)
#  loader                :string(255)
#  state                 :string(255)
#  loader_hits_cache     :integer(8)      default(0)
#  player_hits_cache     :integer(8)      default(0)
#  flash_hits_cache      :integer(8)      default(0)
#  archived_at           :datetime
#  created_at            :datetime
#  updated_at            :datetime
#  player_mode           :string(255)     default("stable")
#  requests_s3_cache     :integer(8)      default(0)
#  traffic_s3_cache      :integer(8)      default(0)
#  traffic_voxcast_cache :integer(8)      default(0)
#
# Indexes
#
#  index_sites_on_created_at                     (created_at)
#  index_sites_on_hostname                       (hostname)
#  index_sites_on_player_hits_cache_and_user_id  (player_hits_cache,user_id)
#  index_sites_on_user_id                        (user_id)
#

