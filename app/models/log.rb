# == Schema Information
#
# Table name: logs
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  name       :string(255)
#  hostname   :string(255)
#  state      :string(255)
#  file       :string(255)
#  started_at :datetime
#  ended_at   :datetime
#  created_at :datetime
#  updated_at :datetime
#

require 'carrierwave/orm/mongoid'

class Log
  include Mongoid::Document
  include Mongoid::Versioning
  
  field :name
  field :hostname
  field :state, :default => "unparsed"
  field :file
  field :started_at, :type => DateTime
  field :ended_at,   :type => DateTime
  
  # ensure there is no confusion about S3 Class
  autoload :Amazon, 'log/amazon'
  autoload :S3,     'log/amazon/s3'
  
  attr_accessible :name
  
  mount_uploader :file, LogUploader
  
  # ===============
  # = Validations =
  # ===============
  
  validates :name,       :presence => true
  validates :started_at, :presence => true
  validates :ended_at,   :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  after_create :delay_parse
  
  # =================
  # = State Machine =
  # =================
  
  # state_machine :initial => :unprocessed do
  #   before_transition :unprocessed => :processed, :do => :parse_and_create_usages!
  #   
  #   event(:process) { transition :unprocessed => :processed }
  # end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def name=(attribute)
    write_attribute :name, attribute
    set_dates_and_hostname_from_name
  end
  
  def unparsed?
    state == "unparsed"
  end
  
  def parse
    parse_and_create_usages!
    update_attributes!(:state => "parsed")
  end
  
  def respond_to?(method, include_private_methods = false)
    (Mongoid.allow_dynamic_fields && @attributes && @attributes.has_key?(method.to_s)) || super(method)
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.delay_fetch_and_create_new_logs
    # Sites
    Log::Voxcast.delay_fetch_download_and_create_new_logs
    Log::Amazon::S3::Player.delay_fetch_and_create_new_logs
    Log::Amazon::S3::Loaders.delay_fetch_and_create_new_logs
    Log::Amazon::S3::Licenses.delay_fetch_and_create_new_logs
  end
  
  def self.config
    yml[self.to_s.gsub("Log::", '').to_sym].to_options
  end
  
  def self.create_new_logs(new_logs_names)
    existings_logs_names = only(:name).any_in(:name => new_logs_names).map(&:name)
    new_logs = new_logs_names.inject([]) do |new_logs, logs_name|
      new_logs << new(:name => logs_name)
    end
    new_logs = new_logs.select { |l| existings_logs_names.exclude? l.name }
    new_logs.each { |l| l.save }
  rescue => ex
    HoptoadNotifier.notify(ex)
  end
  
private
  
  # after_create
  def delay_parse
    delay(:priority => 20).parse
  end
  
  # Don't forget to delete this logs_file after using it, thx!
  def copy_logs_file_to_tmp
    logs_file = File.new(Rails.root.join("tmp/#{name}"), 'w')
    logs_file.write(file.read)
    logs_file.flush
  end
  
  def self.yml
    config_path = Rails.root.join('config', 'logs.yml')
    @default_storage ||= YAML::load_file(config_path)
    @default_storage.to_options
  rescue
    raise StandardError, "Logs config file '#{config_path}' doesn't exist."
  end
  
end