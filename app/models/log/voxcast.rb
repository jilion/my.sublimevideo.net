class Log::Voxcast < Log

  field :referrers_parsed_at,  :type => DateTime
  field :user_agents_parsed_at,  :type => DateTime

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
  after_create :delay_parse_referrers, :delay_parse_user_agents

  # =================
  # = Class Methods =
  # =================

  def self.delay_download_and_create_new_logs
    %w[download_and_create_new_non_ssl_logs, download_and_create_new_ssl_logs].each do |method_name|
      send(method_name) unless Delayed::Job.already_delayed?("%Log::Voxcast%#{method_name}%")
    end
  end
  
  def self.download_and_create_new_non_ssl_logs
    download_and_create_new_logs(VoxcastCDN.non_ssl_hostname, __method__)
  end
  def self.download_and_create_new_ssl_logs
    download_and_create_new_logs(VoxcastCDN.ssl_hostname, __method__)
  end
  
  def self.download_and_create_new_logs(hostname, method)
    new_log_time = nil
    while (new_log_time = log_time(hostname, new_log_time)) <= Time.now.to_i do
      new_log_name = log_name(hostname, new_log_time)
      new_log_file = VoxcastCDN.log_download(new_log_name)
      create(name: new_log_name, file: new_log_file) if new_log_file
    end

    delay(priority: 0, run_at: (new_log_time - Time.now.to_i + 1).seconds.from_now).send(method)
  end

  def self.log_name(hostname, time)

  end

  def self.log_time(hostname, new_log_file)

  end

  def self.parse_log_for_referrers(id)
    log = find(id)
    log.parse_and_create_referrers!
  end

  def self.parse_log_for_user_agents(id)
    log = find(id)
    log.parse_and_create_user_agents!
  end

  # ====================
  # = Instance Methods =
  # ====================

  # Used in Log#parse_log
  def parse_and_create_usages!
    logs_file = copy_logs_file_to_tmp
    trackers = LogAnalyzer.parse(logs_file, self.class.config[:file_format_class_name])
    SiteUsage.create_usages_from_trackers!(self, trackers)
    File.delete(logs_file.path)
  end

  def parse_and_create_referrers!
    unless referrers_parsed?
      logs_file = copy_logs_file_to_tmp
      trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastReferrers')
      Referrer.create_or_update_from_trackers!(trackers)
      File.delete(logs_file.path)
      self.referrers_parsed_at = Time.now.utc
      self.save
    end
  end

  def referrers_parsed?
    referrers_parsed_at.present?
  end

  def parse_and_create_user_agents!
    unless user_agents_parsed?
      logs_file = copy_logs_file_to_tmp
      trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastUserAgents')
      UsrAgent.create_or_update_from_trackers!(self, trackers)
      File.delete(logs_file.path)
      self.user_agents_parsed_at = Time.now.utc
      self.save
    end
  end

  def user_agents_parsed?
    user_agents_parsed_at.present?
  end

private

  # before_validation
  def download_and_set_log_file
    self.file = VoxcastCDN.download_log(name) unless file.present?
  end

  # after_create
  def delay_parse_referrers
    self.class.delay(:priority => 90, :run_at => 1.minute.from_now).parse_log_for_referrers(id)
  end

  # after_create
  def delay_parse_user_agents
    self.class.delay(:priority => 95, :run_at => 1.minute.from_now).parse_log_for_user_agents(id)
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
