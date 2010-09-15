class Log::Voxcast < Log
  
  field :referers_parsed_at,  :type => DateTime
  
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
  
  before_validation :download_and_set_log_file, :on => :create
  after_create :delay_parse_referers
  
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
  
  def parse_and_create_referers!
    unless referers_parsed?
      logs_file = copy_logs_file_to_tmp
      trackers = LogAnalyzer.parse(logs_file, 'LogsFileFormat::VoxcastReferers')
      Referer.create_or_update_from_trackers!(trackers)
      File.delete(logs_file.path)
      self.referers_parsed_at = Time.now.utc
      self.save
    end
  end
  
  def referers_parsed?
    referers_parsed_at.present?
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.delay_fetch_download_and_create_new_logs(interval = 1.minute)
    unless Delayed::Job.already_delayed?('%Log::Voxcast%fetch_download_and_create_new_logs%')
      delay(:priority => 10, :run_at => interval.from_now).fetch_download_and_create_new_logs
    end
  end
  
  def self.fetch_download_and_create_new_logs
    delay_fetch_download_and_create_new_logs # relaunch the process in 1 min
    new_logs_names = VoxcastCDN.fetch_logs_names
    create_new_logs(new_logs_names)
  end
  
  def self.parse_log_for_referers(id)
    log = find(id)
    log.parse_and_create_referers!
  end
  
private
  
  # before_validation
  def download_and_set_log_file
    self.file = VoxcastCDN.logs_download(name)
  end
  
  # after_create
  def delay_parse
    super if hostname == 'cdn.sublimevideo.net'
  end
  
  # after_create
  def delay_parse_referers
    self.class.delay(:priority => 90).parse_log_for_referers(id)
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