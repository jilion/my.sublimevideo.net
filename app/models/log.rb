require 'carrierwave/orm/mongoid'

class Log
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :hostname
  field :started_at, :type => DateTime
  field :ended_at,   :type => DateTime
  field :parsed_at,  :type => DateTime

  index :name, :unique => true
  index :started_at
  index :ended_at

  # ensure there is no confusion about S3 Class
  autoload :Amazon, 'log/amazon'
  autoload :S3,     'log/amazon/s3'

  attr_accessible :name

  mount_uploader :file, LogUploader # on file_filename field!

  # ===============
  # = Validations =
  # ===============

  validates :name,       :presence => true, :uniqueness => true
  validates :started_at, :presence => true
  validates :ended_at,   :presence => true

  # =============
  # = Callbacks =
  # =============

  after_create :delay_parse

  # ====================
  # = Instance Methods =
  # ====================

  def name=(attribute)
    write_attribute :name, attribute
    set_dates_and_hostname_from_name
  end

  def parsed?
    parsed_at.present?
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
    new_logs_names.each do |name|
      if existings_logs_names.exclude?(name)
        begin
          create(:name => name)
        rescue => ex
          HoptoadNotifier.notify(ex)
        end
      end
    end
  rescue => ex
    HoptoadNotifier.notify(ex)
  end

  def self.parse_log(id)
    log = find(id)
    log.parse_and_create_usages!
    log.parsed_at = Time.now.utc
    log.save
  end

private

  # after_create
  def delay_parse
    self.class.delay(:priority => 20).parse_log(id)
  end

  # Don't forget to delete this logs_file after using it, thx!
  def copy_logs_file_to_tmp
    Notify.send("Log File ##{id} not present at copy") unless file.present?
    logs_file = File.new(Rails.root.join("tmp/#{name}"), 'w', :encoding => 'ASCII-8BIT')
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
