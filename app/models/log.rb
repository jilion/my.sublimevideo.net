# encoding: utf-8
require 'tempfile'

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

  mount_uploader :file, LogUploader, mount_on: :file_filename

  # ===============
  # = Validations =
  # ===============

  validates :name,       presence: true, uniqueness: true
  validates :started_at, :ended_at, presence: true

  # =================
  # = Class Methods =
  # =================

  def self.create_new_logs(new_logs_names)
    existings_logs_names = only(:name).any_in(name: new_logs_names).map(&:name)
    (new_logs_names - existings_logs_names).each do |name|
      with(safe: true).create(name: name)
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
      trackers = trackers.find { |t| t.options[:title] == options[:title] }.categories
    end
    trackers
  end

private

  def with_log_file_in_tmp(&block)
    log_file = Tempfile.new([name, '.log.gz'], encoding: 'ASCII-8BIT')
    rescue_and_retry(5, Excon::Errors::SocketError) do
      begin
         log_file.write(file.read)
      rescue NoMethodError, Excon::Errors::NotFound => ex
        if is_a?(Log::Voxcast)
          self.file = VoxcastWrapper.download_log(name)
          self.save
          log_file.write(file.read)
        else
          raise ex
        end
      end
    end
    result = yield(log_file)
    log_file.close!
    result
  end

end
