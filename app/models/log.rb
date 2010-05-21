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
  
  # ===============
  # = Validations =
  # ===============
  
  validates :name,       :presence => true
  validates :started_at, :presence => true
  validates :ended_at,   :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :download_and_set_log_file
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :unprocessed do
    event(:process) { transition :unprocessed => :processed }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def name=(attribute)
    write_attribute :name, attribute
    set_dates_and_hostname_from_name
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.download_and_save_new_logs
    new_logs_names = CDN.logs_names
    existings_logs_names = Log.select(:name).where(:name => new_logs_names).map(&:name)
    new_logs = new_logs_names.inject([]) do |new_logs, logs_name|
      new_logs << new(:name => logs_name)
    end
    new_logs = new_logs.select { |l| existings_logs_names.exclude? l.name }
    new_logs.each { |l| l.save }
  end
  
private
  
  # before_create
  def download_and_set_log_file
    self.file = CDN.logs_download(name)
  end
  
  def set_dates_and_hostname_from_name
    if matches = name.match(/^(.+)\.log\.(\d+)-(\d+)\.\w+$/)
      self.hostname   = matches[1]
      self.started_at = Time.at(matches[2].to_i)
      self.ended_at   = Time.at(matches[3].to_i)
    end
  end
  
end