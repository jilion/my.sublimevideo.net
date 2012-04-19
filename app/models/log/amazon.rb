# encoding: utf-8

class Log::Amazon < Log

  # ===============
  # = Validations =
  # ===============

  validates :file, presence: true, on: :update

  # =============
  # = Callbacks =
  # =============

  before_validation :set_hostname, on: :create
  before_validation :set_log_file, on: :create

  # =================
  # = Class Methods =
  # =================

  def self.delay_fetch_and_create_new_logs(interval=1.hour)
    unless Delayed::Job.already_delayed?("%#{self.to_s}%fetch_and_create_new_logs%")
      delay(priority: 10, run_at: interval.from_now).fetch_and_create_new_logs
    end
  end

  def self.fetch_and_create_new_logs
    delay_fetch_and_create_new_logs # relaunch the process in 60 min
    new_logs_names = fetch_new_logs_names
    create_new_logs(new_logs_names)
  end

private

  def self.fetch_new_logs_names
    options = {
      'prefix' => config[:store_dir],
      :remove_prefix => true
    }
    if last_log = self.where(created_at: { "$gt" => 7.day.ago }).desc(:name).first
      options['marker'] = config[:store_dir] + marker(last_log)
    end
    rescue_and_retry(7, Aws::AwsError) { ::S3.logs_name_list(options) }
  end

  # ====================
  # = Instance Methods =
  # ====================

public

  # Used in Log#parse_log
  def parse_and_create_usages!
    trackers = trackers(self.class.config[:file_format_class_name])
    SiteUsage.create_usages_from_trackers!(self, trackers)
  end

private

  # before_validation
  def set_log_file
    write_attribute :file_filename, name
  end

  # before_validation
  def set_hostname
    self.hostname = self.class.config[:hostname]
  end

end

