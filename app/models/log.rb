require 'tempfile'
require_dependency 'log_analyzer'
require_dependency 'notify'

# encoding: utf-8
class Log
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :hostname
  field :started_at, type: DateTime
  field :ended_at,   type: DateTime
  field :parsed_at,  type: DateTime

  index({ name: 1 }, unique: true)
  index({ created_at: 1, _type: 1 }, background: true) # Log::Amazon#fetch_new_logs_names & Log::Voxcast#next_log_ended_at

  attr_accessible :name

  mount_uploader :file, LogUploader, mount_on: :file_filename

  # ===============
  # = Validations =
  # ===============

  validates :name,       presence: true, uniqueness: true
  validates :started_at, presence: true
  validates :ended_at,   presence: true

  # =============
  # = Callbacks =
  # =============

  after_create :delay_parse

  # =================
  # = Class Methods =
  # =================

  def self.config
    yml[self.to_s.gsub("Log::", '').to_sym].symbolize_keys
  end

  def self.create_new_logs(new_logs_names)
    existings_logs_names = only(:name).any_in(name: new_logs_names).map(&:name)
    (new_logs_names - existings_logs_names).each do |name|
      with(safe: true).create(name: name)
    end
  end

  def self.parse_log(id)
    log = find(id)
    unless log.parsed_at?
      log.parse_and_create_usages!
      log.with(safe: true).update_attribute(:parsed_at, Time.now.utc)
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  def name=(attribute)
    write_attribute :name, attribute
    set_dates_and_hostname_from_name
  end

  def day
    @day ||= started_at.change(hour: 0, min: 0, sec: 0, usec: 0).to_time
  end

  def month
    @month ||= started_at.change(day: 1, hour: 0, min: 0, sec: 0, usec: 0).to_time
  end

  def trackers(log_format, options = {})
    trackers = with_log_file_in_tmp { |file| LogAnalyzer.parse(file, log_format) }
    if options[:title].present?
      trackers = trackers.detect { |t| t.options[:title] == options[:title] }.categories
    end
    trackers
  end

private

  # after_create
  def delay_parse
    self.class.delay(queue: 'low', at: 5.seconds.from_now.to_i).parse_log(id) # lets finish the upload
  end

  def with_log_file_in_tmp(&block)
    Notify.send("Log File ##{id} not present at copy") unless file.present?
    log_file = Tempfile.new([name, '.log.gz'], encoding: 'ASCII-8BIT')
    rescue_and_retry(5, Excon::Errors::SocketError) do
      begin
        log_file.write(file.read)
      rescue NoMethodError, Excon::Errors::NotFound => ex
        if is_a?(Log::Voxcast)
          self.file = CDN::VoxcastWrapper.download_log(name)
          self.save
          log = Log.find(self.id) # hard reload
          log_file.write(log.file.read)
        else
          raise ex
        end
      end
      log_file.close
    end
    result = yield(log_file)
    log_file.unlink
    result
  end

  def self.yml
    config_path = Rails.root.join('config', 'logs.yml')
    @default_storage ||= YAML::load_file(config_path)
    @default_storage.symbolize_keys
  rescue
    raise StandardError, "Logs config file '#{config_path}' doesn't exist."
  end

end
