# == Schema Information
#
# Table name: sites
#
#  id                :integer         not null, primary key
#  user_id           :integer
#  hostname          :string(255)
#  dev_hostnames     :string(255)
#  token             :string(255)
#  license           :string(255)
#  loader            :string(255)
#  state             :string(255)
#  loader_hits_cache :integer         default(0)
#  js_hits_cache     :integer         default(0)
#  flash_hits_cache  :integer         default(0)
#  created_at        :datetime
#  updated_at        :datetime
#

class Site < ActiveRecord::Base
  
  attr_accessible :hostname, :dev_hostnames
  uniquify :token, :chars => ('a'..'z').to_a + ('0'..'9').to_a
  mount_uploader :license, LicenseUploader
  mount_uploader :loader, LoaderUploader
  
  cattr_accessor :per_page
  self.per_page = 6
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
  has_many :usages, :class_name => "SiteUsage"
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :by_date, lambda { |way| order("created_at #{way || 'desc'}") }
  scope :by_hostname, lambda { |way| order("hostname #{way || 'asc'}") }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,     :presence => true
  validates :hostname, :presence => true, :uniqueness => { :scope => :user_id }, :production_hostname => true
  validates :dev_hostnames, :hostnames => true
  validate  :must_be_active_to_update_hostnames
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_default_dev_hostnames
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    before_transition :pending => :activate, :do => :set_loader_file
    before_transition :on => :activate,      :do => :set_license_file
    after_transition  :inactive => :active,  :do => :purge_license_file
    
    event(:activate)   { transition [:pending, :inactive] => :active }
    event(:deactivate) { transition :active => :inactive }
    event(:archive)    { transition all => :archived    }
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
  
  def set_loader_file
    set_template("loader")
  end
  
  def set_license_file
    set_template("license")
  end
  
  def purge_loader_file
    CDN.purge("/js/#{token}.js")
  end
  
  def purge_license_file
    CDN.purge("/l/#{token}.js")
  end
  
private
  
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
  
  def set_template(name)
    template = ERB.new(File.new(Rails.root.join("app/templates/sites/#{name}.js.erb")).read)
    
    tempfile = Tempfile.new(name, "#{Rails.root}/tmp")
    tempfile.print template.result(binding)
    tempfile.flush
    
    self.send("#{name}=", tempfile)
  end
  
end
