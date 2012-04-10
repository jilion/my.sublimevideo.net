class Log::Voxcast < Log
  field :stats_parsed_at,       type: DateTime
  field :referrers_parsed_at,   type: DateTime
  field :user_agents_parsed_at, type: DateTime
  field :video_tags_parsed_at,  type: DateTime

  attr_accessible :file

  # ================
  # = Associations =
  # ================

  references_many :usages, :class_name => "SiteUsage", :foreign_key => :log_id

  # ===============
  # = Validations =
  # ===============

  validates :file, :presence => true

  # =============
  # = Callbacks =
  # =============

  before_validation :download_and_set_log_file

  # =================
  # = Class Methods =
  # =================

  def self.download_and_create_new_logs
    %w[download_and_create_new_non_ssl_logs download_and_create_new_ssl_logs].each do |method_name|
      send(method_name) unless Delayed::Job.already_delayed?("%Log::Voxcast%#{method_name}%")
    end
  end

  def self.download_and_create_new_non_ssl_logs
    download_and_create_new_logs_and_redelay(VoxcastCDN.non_ssl_hostname, __method__)
  end
  def self.download_and_create_new_ssl_logs
    download_and_create_new_logs_and_redelay(VoxcastCDN.ssl_hostname, __method__)
  end

  def self.download_and_create_new_logs_and_redelay(hostname, method)
    new_log_ended_at = nil
    while (new_log_ended_at = next_log_ended_at(hostname, new_log_ended_at)) < Time.now.utc do
      new_log_name = log_name(hostname, new_log_ended_at)
      new_log_file = VoxcastCDN.download_log(new_log_name)
      safely.create(name: new_log_name, file: new_log_file) if new_log_file
    end
    unless Delayed::Job.already_delayed?("%Log::Voxcast%#{method}%")
      delay(priority: RecurringJob::PRIORITIES[:logs], run_at: new_log_ended_at).send(method)
    end
  end

  def self.log_name(hostname, ended_at)
    "#{hostname}.log.#{ended_at.to_i - 60}-#{ended_at.to_i}.gz"
  end

  def self.next_log_ended_at(hostname, last_log_ended_at = nil)
    last_ended_at = last_log_ended_at ||
      where(hostname: hostname, created_at: { "$gt" => 7.day.ago }).order_by([:ended_at, :desc]).first.try(:ended_at) ||
      1.minute.ago.change(sec: 0)
    last_ended_at + 60.seconds
  end

  class << self
    %w[stats referrers user_agents video_tags].each do |type|
      define_method("parse_log_for_#{type}") do |id|
        log = find(id)
        unless log.send "#{type}_parsed_at?"
          log.send "parse_and_create_#{type}!"
          log.safely.update_attribute("#{type}_parsed_at", Time.now.utc)
        end
      end
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  # Used in Log#parse_log
  def parse_and_create_usages!
    trackers = trackers(self.class.config[:file_format_class_name])
    SiteUsage.create_usages_from_trackers!(self, trackers)
  end

  def parse_and_create_stats!
    trackers = trackers('LogsFileFormat::VoxcastStats')
    Stat.create_stats_from_trackers!(self, trackers)
  end

  def parse_and_create_referrers!
    trackers = trackers('LogsFileFormat::VoxcastReferrers')
    Referrer.create_or_update_from_trackers!(trackers)
  end

  def parse_and_create_user_agents!
    trackers = trackers('LogsFileFormat::VoxcastUserAgents')
    UsrAgent.create_or_update_from_trackers!(self, trackers)
  end

  def parse_and_create_video_tags!
    trackers = trackers('LogsFileFormat::VoxcastVideoTags')
    VideoTag.create_or_update_from_trackers!(trackers)
  end

  def minute
    @minute ||= started_at.change(sec: 0, usec: 0).to_time
  end

  def hour
    started_at.change(min: 0, sec: 0, usec: 0).to_time
  end

private

  # after_create
  def delay_parse
    self.class.delay(priority: 1).parse_log_for_stats(id)
    self.class.delay(priority: 2, run_at: 5.seconds.from_now).parse_log_for_video_tags(id)
    self.class.delay(priority: 3, run_at: 10.seconds.from_now).parse_log(id)
    self.class.delay(priority: 4, run_at: 10.seconds.from_now).parse_log_for_user_agents(id)
    self.class.delay(priority: 5, run_at: 10.seconds.from_now).parse_log_for_referrers(id)
  end

  # before_validation
  def download_and_set_log_file
    self.file = VoxcastCDN.download_log(name) unless file.present?
  end

  # call from name= in Log
  def set_dates_and_hostname_from_name
    if matches = name.match(/^(.+)\.log\.(\d+)-(\d+)\.\w+$/)
      self.hostname   ||= matches[1]
      self.started_at ||= Time.at(matches[2].to_i).utc
      self.ended_at   ||= Time.at(matches[3].to_i).utc
    end
  end

end
