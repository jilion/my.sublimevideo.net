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

class Log::Amazon::S3::Loaders < Log::Amazon::S3
  
  # ================
  # = Associations =
  # ================
  
  # has_many :usages, :class_name => "SiteUsage"
  
end