# == Schema Information
#
# Table name: video_profiles
#
#  id              :integer         not null, primary key
#  title           :string(255)
#  description     :text
#  name            :string(255)
#  extname         :string(255)
#  posterframeable :boolean
#  min_width       :integer
#  min_height      :integer
#  versions_count  :integer         default(0)
#  created_at      :datetime
#  updated_at      :datetime
#

class VideoProfile < ActiveRecord::Base
  
  attr_accessible :title, :description, :posterframeable, :min_width, :min_height
  
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
  validates_uniqueness_of :name, :scope => :extname
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_defaults
  
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
    versions.active.first
  end
  
private
  
  # before_create
  def set_defaults
    write_attribute(:posterframeable, 0) unless posterframeable.present?
    write_attribute(:min_width, 0) unless min_width.present?
    write_attribute(:min_height, 0) unless min_height.present?
  end
  
end
