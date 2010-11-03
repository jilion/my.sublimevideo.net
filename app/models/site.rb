class Site < ActiveRecord::Base
  
  DEFAULT_DEV_DOMAINS = '127.0.0.1, localhost'
  PLAYER_MODES = %w[dev beta stable]
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 100
  
  # Versioning
  has_paper_trail
  
  attr_accessor :user_attributes
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
  
  scope :archived,     where(:state => 'archived')
  scope :not_archived, where(:state.not_eq => 'archived')
  
  scope :by_hostname,             lambda { |way = 'asc'| order("#{Site.quoted_table_name}.hostname #{way}") }
  scope :by_user,                 lambda { |way = 'desc'| includes(:user).order("#{User.quoted_table_name}.first_name #{way}, #{User.quoted_table_name}.email #{way}") }
  scope :by_state,                lambda { |way = 'desc'| order("#{Site.quoted_table_name}.state #{way}") }
  scope :by_google_rank,          lambda { |way = 'desc'| where(:google_rank.gte => 0).order("#{Site.quoted_table_name}.google_rank #{way}") }
  scope :by_alexa_rank,           lambda { |way = 'desc'| where(:alexa_rank.gte => 1).order("#{Site.quoted_table_name}.alexa_rank #{way}") }
  scope :by_date,                 lambda { |way = 'desc'| order("#{Site.quoted_table_name}.created_at #{way}") }
  scope :search, lambda { |q| includes(:user).where(["LOWER(#{Site.quoted_table_name}.hostname) LIKE LOWER(?) OR LOWER(#{Site.quoted_table_name}.dev_hostnames) LIKE LOWER(?) OR LOWER(#{User.quoted_table_name}.email) LIKE LOWER(?) OR LOWER(#{User.quoted_table_name}.first_name) LIKE LOWER(?) OR LOWER(#{User.quoted_table_name}.last_name) LIKE LOWER(?)", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"]) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,            :presence => true
  validates :plan,            :presence => { :message => "Please choose a plan" }
  validates :hostname,        :hostname_uniqueness => true, :hostname => true
  validates :dev_hostnames,   :dev_hostnames => true
  validates :extra_hostnames, :extra_hostnames => true
  validates :player_mode,     :inclusion => { :in => PLAYER_MODES }
  validate  :at_least_one_domain_set
  validate  :must_be_active_to_update_hostnames
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_user_attributes
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
    
    state :beta # Pending, using in lib/one_time/site.rb
    
    state :active, :suspended, :archived do
      validates_presence_of :hostname
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
  
  def set_user_attributes
    user.attributes = user_attributes if user && user_attributes.present?
  end
  
  def template_hostnames
    hostnames = []
    hostnames << hostname if hostname.present?
    hostnames += extra_hostnames.split(', ') if extra_hostnames.present?
    hostnames += dev_hostnames.split(', ') if dev_hostnames.present?
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
  
  def update_ranks
    ranks = PageRankr.ranks(hostname)
    self.google_rank = ranks[:google]
    self.alexa_rank  = ranks[:alexa]
    self.save
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
  
private
  
  def self.referrer_match_hostname?(referrer, hostname, path = '', wildcard = false)
    if path || wildcard
      referrer =~ /^.+:\/\/(#{wildcard ? '.*' : 'www'}\.)?#{hostname}#{"(\:[0-9]+)?\/#{path}" if path.present?}.*$/
    else
      URI.parse(referrer).host =~ /^(www\.)?#{hostname}$/
    end
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
  
  # validate
  def at_least_one_domain_set
    unless active? || hostname.present? || dev_hostnames.present? || extra_hostnames.present?
      errors[:base] << "Please set at least a development or an extra domain"
    end
  end
  
  # validate
  def must_be_active_to_update_hostnames
    if !new_record? && pending?
      message = "cannot be updated when site in progress, please wait before update again"
      errors[:hostname]        << message if hostname_changed?
      errors[:extra_hostnames] << message if extra_hostnames_changed?
      errors[:dev_hostnames]   << message if dev_hostnames_changed?
      errors[:path]            << message if path_changed?
      errors[:wildcard]        << message if wildcard_changed?
    end
  end
  
  # before_create
  def set_default_dev_hostnames
    write_attribute(:dev_hostnames, DEFAULT_DEV_DOMAINS) unless dev_hostnames.present?
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
#  id              :integer         not null, primary key
#  user_id         :integer
#  hostname        :string(255)
#  dev_hostnames   :string(255)
#  token           :string(255)
#  license         :string(255)
#  loader          :string(255)
#  state           :string(255)
#  archived_at     :datetime
#  created_at      :datetime
#  updated_at      :datetime
#  player_mode     :string(255)     default("stable")
#  google_rank     :integer
#  alexa_rank      :integer
#  path            :string(255)
#  wildcard        :boolean
#  extra_hostnames :string(255)
#  plan_id         :integer
#
# Indexes
#
#  index_sites_on_created_at  (created_at)
#  index_sites_on_hostname    (hostname)
#  index_sites_on_plan_id     (plan_id)
#  index_sites_on_user_id     (user_id)
#
