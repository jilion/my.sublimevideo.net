# == Schema Information
#
# Table name: sites
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  hostname      :string(255)
#  dev_hostnames :string(255)
#  token         :string(255)
#  license       :string(255)
#  state         :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#

class Site < ActiveRecord::Base
  
  attr_accessible :hostname, :dev_hostnames
  uniquify :token
  mount_uploader :license, LicenseUploader
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
  
  # ==========
  # = Scopes =
  # ==========
  
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,     :presence => true
  validates :hostname, :presence => true, :uniqueness => { :scope => :user_id }, :production_hostname => true
  validates :dev_hostnames, :hostnames => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_default_dev_hostnames
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    before_transition :pending => :active, :do => :set_license_file
    
    event(:activate)   { transition :pending => :active }
    event(:deactivate) { transition :active => :pending }
    event(:archive)    { transition all => :archived }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # add scheme & parse
  def hostname=(attribute)
    attribute = "http://#{attribute}" unless attribute =~ %r(^\w+://.*$)
    attribute.gsub! %r(://www\.), '://'
    write_attribute :hostname, URI.parse(attribute).host
  rescue
    write_attribute :hostname, attribute
  end
  
  # add scheme & parse
  def dev_hostnames=(attribute)
    if attribute.present?
      attribute = attribute.split(',').select { |h| h.present? }.map do |host|
        host.strip!
        host = "http://#{host}" unless host =~ %r(^\w+://.*$)
        host.gsub! %r(://www\.), '://'
        URI.parse(host).host
      end.join(', ')
    end
    write_attribute :dev_hostnames, attribute
  rescue
    write_attribute :dev_hostnames, attribute
  end
  
  def licenses_hashes
    licenses  = [hostname]
    licenses += dev_hostnames.split(', ')
    licenses.map! { |l| "'" + Digest::SHA1.hexdigest("@#{l}") + "'" }
    licenses.join(',')
  end
  
  def set_license_file
    template = ERB.new(File.new(Rails.root.join('app/templates/sites/license.js.erb')).read)
    
    tempfile = Tempfile.new('license', "#{Rails.root}/tmp")
    tempfile.print template.result(binding)
    tempfile.flush
    
    self.license = tempfile
  end
  
private
  
  # before_create
  def set_default_dev_hostnames
    write_attribute(:dev_hostnames, "localhost, 127.0.0.1") unless dev_hostnames.present?
  end
  
end