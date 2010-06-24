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

class Log::Voxcast < Log
  
  # ================
  # = Associations =
  # ================
  
  has_many :site_usages
  
  # ===============
  # = Validations =
  # ===============
  
  validates :file,       :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :download_and_set_log_file, :on => :create
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # before_transition on process
  def parse_and_create_usages!
    logs_file = copy_logs_file_to_tmp
    trackers = LogAnalyzer.parse(logs_file, self.class.config[:file_format_class_name])
    SiteUsage.create_usages_from_trackers!(self, trackers)
    File.delete(logs_file.path)
  rescue => ex
    HoptoadNotifier.notify(ex)
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.delay_fetch_download_and_create_new_logs(minutes = 1.minute)
    unless Delayed::Job.already_delayed?('%Log::Voxcast%fetch_download_and_create_new_logs%')
      delay(:priority => 10, :run_at => minutes.from_now).fetch_download_and_create_new_logs
    end
  end
  
  def self.fetch_download_and_create_new_logs
    new_logs_names = VoxcastCDN.fetch_logs_names
    create_new_logs(new_logs_names)
    delay_fetch_download_and_create_new_logs # relaunch the process in 1 min
  rescue => ex
    HoptoadNotifier.notify(ex)
    delay_fetch_download_and_create_new_logs # relaunch the process in 1 min
  end
  
private
  
  # before_validation
  def download_and_set_log_file
    self.file = VoxcastCDN.logs_download(name)
  end
  
  # call from name= in Log
  def set_dates_and_hostname_from_name
    if matches = name.match(/^(.+)\.log\.(\d+)-(\d+)\.\w+$/)
      self.hostname   ||= matches[1]
      self.started_at ||= Time.at(matches[2].to_i)
      self.ended_at   ||= Time.at(matches[3].to_i)
    end
  end
  
end