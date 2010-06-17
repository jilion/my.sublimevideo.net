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

class Log::CloudfrontDownload < Log
  
  # ================
  # = Associations =
  # ================
  
  # has_many :site_usages
  
  # ===============
  # = Validations =
  # ===============
  
  validates :file, :presence => true, :on => :update

  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_log_file, :on => :create
  before_validation :set_hostname, :on => :create
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # before_transition on process
  def parse_and_create_usages!
  #   logs_file = copy_logs_file_to_tmp
  #   trackers = LogAnalyzer.parse(logs_file, self.class.config[:file_format_class_name])
  #   SiteUsage.create_usages_from_trackers!(self, trackers)
  #   File.delete(logs_file.path)
  # rescue => ex
  #   HoptoadNotifier.notify(ex)
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.delay_fetch_and_create_new_logs(minutes = 60.minute)
    unless fetch_and_create_new_logs_already_delayed?(minutes)
      delay(:priority => 10, :run_at => minutes.from_now).fetch_and_create_new_logs
    end
  end
  
  def self.fetch_and_create_new_logs
    new_logs_names = fetch_new_logs_names
    create_new_logs(new_logs_names)
    delay_fetch_and_create_new_logs # relaunch the process in 60 min
  end
  
private
  
  # before_validation
  def set_log_file
    write_attribute :file, name
  end
  
  # before_validation
  def set_hostname
    self.hostname = self.class.config[:hostname]
  end
  
  # call from name= in Log
  def set_dates_and_hostname_from_name
    if matches = name.match(/^[A-Z0-9]+\.([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})\.[a-zA-Z0-9]+\.gz$/)
      self.started_at ||= Time.zone.parse(matches[1]) + matches[2].to_i.hours
      self.ended_at   ||= started_at + 1.hour
    end
  end
  
  def self.fetch_and_create_new_logs_already_delayed?(minutes)
    Delayed::Job.where(
      :handler.matches => '%Log::CloudfrontDownload%fetch_and_create_new_logs%',
      :run_at.gt => (minutes - 10.seconds).from_now
    ).present?
  end
  
  def self.fetch_new_logs_names
    options = {
      'prefix' => 'cloudfront/sublimevideo.videos/download/',
      :remove_prefix => true
    }
    if old_log = self.limit(1).offset(300).order(:created_at.desc).first
      options['marker'] = old_log.read_attribute(:file)
    end
    S3.logs_name_list(options)
  rescue => ex
    HoptoadNotifier.notify(ex)
    []
  end
  
end