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
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :download_and_set_log_file, :on => :create
  
  # =================
  # = Class Methods =
  # =================
  
  def self.delay_new_logs_download(minutes = 1.minute)
    unless logs_download_already_delayed?(minutes)
      delay(:priority => 10, :run_at => minutes.from_now).download_and_save_new_logs
    end
  end
  
  def self.download_and_save_new_logs
    new_logs_names = VoxcastCDN.logs_names
    existings_logs_names = select(:name).where(:name => new_logs_names).map(&:name)
    new_logs = new_logs_names.inject([]) do |new_logs, logs_name|
      new_logs << new(:name => logs_name)
    end
    new_logs = new_logs.select { |l| existings_logs_names.exclude? l.name }
    new_logs.each { |l| l.save }
    delay_new_logs_download # relaunch the process in 1 min
  rescue => ex
    HoptoadNotifier.notify(ex)
  end
  
private
  
  # before_validation
  def download_and_set_log_file
    self.file = VoxcastCDN.logs_download(name)
  end
  
  def set_dates_and_hostname_from_name
    if matches = name.match(/^(.+)\.log\.(\d+)-(\d+)\.\w+$/)
      self.hostname   ||= matches[1]
      self.started_at ||= Time.at(matches[2].to_i)
      self.ended_at   ||= Time.at(matches[3].to_i)
    end
  end
  
  def self.logs_download_already_delayed?(minutes)
    Delayed::Job.where(
      :handler.matches => '%Log::Voxcast%download_and_save_new_logs%',
      :run_at.gt => (minutes - 7.seconds).from_now
    ).present?
  end
  
end