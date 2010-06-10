# == Schema Information
#
# Table name: video_profiles
#
#  id                :integer         not null, primary key
#  title             :string(255)
#  description       :text
#  name              :string(255)
#  extname           :string(255)
#  thumbnailable     :boolean
#  active_version_id :integer
#  versions_count    :integer         default(0)
#  created_at        :datetime
#  updated_at        :datetime
#

class VideoProfile < ActiveRecord::Base
  
  attr_accessible :title, :description, :name, :extname, :thumbnailable, :active_version_id
  
  # ================
  # = Associations =
  # ================
  
  has_many   :versions,       :class_name => "VideoProfileVersion"
  belongs_to :active_version, :class_name => "VideoProfileVersion", :foreign_key => "active_version_id"
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :title,   :presence => true
  validates :extname, :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_default_thumbnailable
  
  # =================
  # = State Machine =
  # =================
  
  # =================
  # = Class Methods =
  # =================
  
  def self.active_profiles
    # connection.select_values(joins(:active_version).select(:panda_profile_id).to_sql)
    # 'where(:active_version_id ^ nil)' doesn't seem to work, it generates 'active_version_id != NULL'
    # but doesn't return any video_profile
    where(:active_version_id > 0)
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
private
  
  # before_create
  def set_default_thumbnailable
    write_attribute(:thumbnailable, 0) unless thumbnailable.present?
  end
  
end