# == Schema Information
#
# Table name: logs
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  hostname   :string(255)
#  state      :string(255)
#  file       :string(255)
#  started_at :datetime
#  ended_at   :datetime
#  created_at :datetime
#  updated_at :datetime
#

class Log < ActiveRecord::Base
  
  attr_accessible :name
  mount_uploader :file, LogUploader
  
  # ================
  # = Associations =
  # ================
  
  has_many :site_usages
  
  # ===============
  # = Validations =
  # ===============
  
  validates :name,       :presence => true
  validates :started_at, :presence => true
  validates :ended_at,   :presence => true
  validates :file,       :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :download_and_set_log_file, :on => :create
  after_create :delay_process
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :unprocessed do
    before_transition :unprocessed => :processed, :do => :parse_and_create_usages!
    
    event(:process) { transition :unprocessed => :processed }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def name=(attribute)
    write_attribute :name, attribute
    set_dates_and_hostname_from_name
  end
  
  def parse_and_create_usages!
    Exceptional.rescue do
      logs_file = copy_logs_file_to_tmp
      trackers = LogAnalyzer.parse(logs_file)
      SiteUsage.create_usages_from_trackers!(self, trackers)
      File.delete(logs_file.path)
    end
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.delay_new_logs_download
    unless Delayed::Job.where(:handler =~ '%download_and_save_new_logs%').present?
      delay(:priority => 10, :run_at => 1.minute.from_now).download_and_save_new_logs
    end
  end
  
  def self.download_and_save_new_logs
    Exceptional.rescue do
      new_logs_names = CDN.logs_names
      existings_logs_names = Log.select(:name).where(:name => new_logs_names).map(&:name)
      new_logs = new_logs_names.inject([]) do |new_logs, logs_name|
        new_logs << new(:name => logs_name)
      end
      new_logs = new_logs.select { |l| existings_logs_names.exclude? l.name }
      new_logs.each { |l| l.save }
      delay_new_logs_download # relaunch the process in 1 min
    end
  end
  
private
  
  # before_validation
  def download_and_set_log_file
    self.file = CDN.logs_download(name)
  end
  
  # after_create
  def delay_process
    delay(:priority => 20).process
  end
  
  def set_dates_and_hostname_from_name
    if matches = name.match(/^(.+)\.log\.(\d+)-(\d+)\.\w+$/)
      self.hostname   = matches[1]
      self.started_at = Time.at(matches[2].to_i)
      self.ended_at   = Time.at(matches[3].to_i)
    end
  end
  
  # Don't forget to delete this logs_file after using it, thx!
  def copy_logs_file_to_tmp
    logs_file = File.new(Rails.root.join("tmp/#{name}"), 'w')
    logs_file.write(file.read)
    logs_file.flush
  end
  
end