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

class Log::Amazon::Cloudfront < Log::Amazon
  
  # ================
  # = Associations =
  # ================
  
  has_many :video_usages
  
private
  
  # call from name= in Log
  def set_dates_and_hostname_from_name
    if matches = name.match(/^[A-Z0-9]+\.([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})\.[a-zA-Z0-9]+\.gz$/)
      self.started_at ||= Time.zone.parse(matches[1]) + matches[2].to_i.hours
      self.ended_at   ||= started_at + 1.hour
    end
  end
  
  # call in Amazon.fetch_new_logs_names
  def self.marker(log, hours = 30.hours)
    hours_ago = (log.started_at - hours).strftime("%Y-%m-%d-%H")
    log.read_attribute(:file).gsub(/\..*/, ".#{hours_ago}")
  end
  
end