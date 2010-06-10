# == Schema Information
#
# Table name: video_profile_versions
#
#  id               :integer         not null, primary key
#  video_profile_id :integer
#  panda_profile_id :string(255)
#  note             :text
#  num              :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class VideoProfileVersion < ActiveRecord::Base
  
  attr_accessible :note, :num
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :profile, :class_name => "VideoProfile", :foreign_key => "video_profile_id"
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
end
