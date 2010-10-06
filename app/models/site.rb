class Site < ActiveRecord::Base
  
  PLAYER_MODES = %w[dev beta stable]
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 100
  
  attr_accessible :hostname, :dev_hostnames
  
  uniquify :token, :chars => Array('a'..'z') + Array('0'..'9')
  
  mount_uploader :license, LicenseUploader
  mount_uploader :loader, LoaderUploader
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
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
  
  scope :archived,     where(:state => 'archived')
  scope :not_archived, where(:state.not_eq => 'archived')
  
  # admin
  scope :with_activity, where(:player_hits_cache.gte => 1)
  # sort
  scope :by_hostname,             lambda { |way| order(:hostname.send(way || 'asc')) }
  scope :by_user,                 lambda { |way| includes(:user).order(:users => [:first_name.send(way || 'desc'), :email.send(way || 'desc')]) }
  scope :by_state,                lambda { |way| order(:state.send(way || 'desc')) }
  scope :by_loader_hits_cache,    lambda { |way| order(:loader_hits_cache.send(way || 'desc')) }
  scope :by_player_hits_cache,    lambda { |way| order(:player_hits_cache.send(way || 'desc')) }
  scope :by_traffic,              lambda { |way| order("(sites.traffic_s3_cache + sites.traffic_voxcast_cache) #{way || 'desc'}") }
  scope :by_flash_percentage,     lambda { |way| where(:player_hits_cache.gt => 0).order("(sites.flash_hits_cache::real/sites.player_hits_cache) #{way || 'desc'}") }
  scope :by_loader_player_ratio,  lambda { |way| where(:player_hits_cache.gt => 0).order("(sites.loader_hits_cache::real/sites.player_hits_cache) #{way || 'desc'}") }
  scope :by_traffic_player_ratio, lambda { |way| where(:player_hits_cache.gt => 0).order("((sites.traffic_s3_cache + sites.traffic_voxcast_cache)::real/sites.player_hits_cache) #{way || 'desc'}") }
  scope :by_google_rank,          lambda { |way| where(:google_rank.gte => 0).order(:google_rank.send(way || 'desc')) }
  scope :by_alexa_rank,           lambda { |way| where(:alexa_rank.gte => 1).order(:alexa_rank.send(way || 'desc')) }
  scope :by_date,                 lambda { |way| order(:created_at.send(way || 'desc')) }
  # search
  scope :search, lambda { |q| includes(:user).where(["LOWER(sites.hostname) LIKE LOWER(?) OR LOWER(sites.dev_hostnames) LIKE LOWER(?) OR LOWER(users.email) LIKE LOWER(?) OR LOWER(users.first_name) LIKE LOWER(?) OR LOWER(users.last_name) LIKE LOWER(?)", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"]) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,          :presence => true
  validates :hostname,      :presence => true, :hostname_uniqueness => true, :production_hostname => true
  validates :dev_hostnames, :hostnames => true
  validates :player_mode,   :inclusion => { :in => PLAYER_MODES }
  validate  :must_be_active_to_update_hostnames
  # BETA
  validate  :limit_site_number_per_user if MySublimeVideo::Release.beta?
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_default_dev_hostnames
  after_create :delay_ranks_update
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    before_transition :on => :activate,   :do => :set_loader_and_license_file
    after_transition  :active => :active, :do => :purge_loader_and_license_file
    
    before_transition :on => :archive,             :do => :set_archived_at
    before_transition :on => [:archive, :suspend], :do => :remove_loader_and_license_file
    after_transition  :on => [:archive, :suspend], :do => :purge_loader_and_license_file
    
    before_transition :on => :unsuspend, :do => :set_loader_and_license_file
    
    event(:activate)   { transition [:pending, :active] => :active }
    event(:suspend)    { transition [:pending, :active] => :suspended }
    event(:unsuspend)  { transition :suspended => :active }
    event(:archive)    { transition [:pending, :active] => :archived }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # add scheme & parse
  def hostname=(attribute)
    if attribute.present?
      attribute.downcase!
      attribute = "http://#{attribute}" unless attribute =~ %r(^\w+://.*$)
      attribute.gsub! %r(://www\.), '://'
      begin
        write_attribute :hostname, URI.parse(attribute).host
      rescue
        write_attribute :hostname, attribute.gsub(%r(.+://(www\.)?), '')
      end
    end
  end
  
  # add scheme & parse
  def dev_hostnames=(attribute)
    if attribute.present?
      attribute.downcase!
      attribute = attribute.split(',').select { |h| h.present? }.map do |host|
        host.strip!
        host = "http://#{host}" unless host =~ %r(^\w+://.*$)
        host.gsub! %r(://www\.), '://'
        begin
          URI.parse(host).host
        rescue
          host.gsub(%r(.+://(www\.)?), '')
        end
      end.join(', ')
      write_attribute :dev_hostnames, attribute
    end
  end
  
  def template_hostnames
    hostnames  = [hostname]
    hostnames += dev_hostnames.split(', ')
    hostnames.map! { |hostname| "'" + hostname + "'" }
    hostnames.join(',')
  end
  
  def set_loader_and_license_file
    set_template("loader")
    set_template("license")
  end
  
  def remove_loader_and_license_file
    self.remove_loader = true
    self.remove_license = true
  end
  
  def purge_loader_and_license_file
    VoxcastCDN.delay.purge("/js/#{token}.js")
    VoxcastCDN.delay.purge("/l/#{token}.js")
  end
  
  def reset_hits_cache!(time)
    # Warning Lot of request here
    self.loader_hits_cache = usages.started_after(time).sum(:loader_hits)
    self.player_hits_cache = usages.started_after(time).sum(:player_hits)
    self.flash_hits_cache  = usages.started_after(time).sum(:flash_hits)
    save!
  end
  
  def in_progress?
    pending?
  end
  
  def update_ranks
    ranks = PageRankr.ranks(hostname)
    self.google_rank = ranks[:google]
    self.alexa_rank  = ranks[:alexa]
    self.save
  end
  
  # use it carefully
  def clear_caches
    self.loader_hits_cache     = 0
    self.player_hits_cache     = 0
    self.flash_hits_cache      = 0
    self.requests_s3_cache     = 0
    self.traffic_s3_cache      = 0
    self.traffic_voxcast_cache = 0
    self.save
  end
  
private
  
  # BETA validate
  def limit_site_number_per_user
    if new_record? && errors[:hostname].blank? && user && user.sites.not_archived.count >= 10
      errors.add(:base, "You can only add up to 10 sites during the beta")
    end
  end
  
  # validate
  def must_be_active_to_update_hostnames
    if !new_record? && pending?
      errors[:hostname] << "can not be updated when site in progress, please wait before update again" if hostname_changed?
      errors[:dev_hostnames] << "can not be updated when site in progress, please wait before update again" if dev_hostnames_changed?
    end
  end
  
  # before_create
  def set_default_dev_hostnames
    write_attribute(:dev_hostnames, "localhost, 127.0.0.1") unless dev_hostnames.present?
  end
  
  # after_create
  def delay_ranks_update
    delay(:priority => 100, :run_at => 30.seconds.from_now).update_ranks
  end
  
  def set_template(name)
    template = ERB.new(File.new(Rails.root.join("app/templates/sites/#{name}.js.erb")).read)
    
    tempfile = Tempfile.new(name, "#{Rails.root}/tmp")
    tempfile.print template.result(binding)
    tempfile.flush
    
    self.send("#{name}=", tempfile)
  end
  
  def set_archived_at
    self.archived_at = Time.now.utc
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
#  google_rank           :integer
#  alexa_rank            :integer
#
# Indexes
#
#  index_sites_on_created_at                     (created_at)
#  index_sites_on_hostname                       (hostname)
#  index_sites_on_player_hits_cache_and_user_id  (player_hits_cache,user_id)
#  index_sites_on_user_id                        (user_id)
#

