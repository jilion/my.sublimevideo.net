# == Schema Information
#
# Table name: video_profiles
#
#  id             :integer         not null, primary key
#  title          :string(255)
#  description    :text
#  name           :string(255)
#  extname        :string(255)
#  thumbnailable  :boolean
#  versions_count :integer         default(0)
#  created_at     :datetime
#  updated_at     :datetime
#

class VideoProfile < ActiveRecord::Base
  
  attr_accessible :title, :description, :name, :extname, :thumbnailable
  
  # ================
  # = Associations =
  # ================
  
  has_many :versions, :class_name => "VideoProfileVersion"
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :title, :extname, :presence => true
  
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
  
  def self.active
    VideoProfileVersion.active.map(&:profile)
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def description
    read_attribute(:description) || ""
  end
  
  def name
    read_attribute(:name) || ""
  end
  
  def experimental_version
    versions.experimental.last || active_version
  end
  
  def active_version
    versions.active.last
  end
  
private
  
  # before_create
  def set_default_thumbnailable
    write_attribute(:thumbnailable, 0) unless thumbnailable.present?
  end
  
end