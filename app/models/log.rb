# == Schema Information
#
# Table name: logs
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  state      :string(255)
#  file       :string(255)
#  started_at :datetime
#  ended_at   :datetime
#  size       :integer
#  created_at :datetime
#  updated_at :datetime
#

class Log < ActiveRecord::Base
  
  mount_uploader :file, LogUploader
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :download_and_set_log_file
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :unprocessed do
    event(:process)   { transition :unprocessed => :processed }
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.download_and_save_new_logs
    all_new_logs_hash    = CDN.logs_list['log_files']['sites']['hostname']['log_file']
    all_new_logs_names   = all_new_logs_hash.map { |l| l['content'] }
    existings_logs_names = Log.select(:name).where(:name => all_new_logs_names).map(&:name)
    new_logs_names       = all_new_logs_names - existings_logs_names
    new_logs_hash        = all_new_logs_hash.select { |l| new_logs_names.include? l['content'] }
    Time.zone = 'Eastern Time (US & Canada)'
    new_logs_hash.each do |logs_hash|
      create(:name       => logs_hash['content'],
             :size       => logs_hash['size'],
             :started_at => logs_hash['start'],
             :ended_at   => logs_hash['end'])
    end
    Time.zone = :utc
  end
  
private
  
  def download_and_set_log_file
    self.file = CDN.logs_download(name)
  end
  
end
