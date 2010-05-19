# == Schema Information
#
# Table name: videos
#
#  id          :integer         not null, primary key
#  user_id     :integer
#  original_id :integer
#  name        :string(255)
#  token       :string(255)
#  file        :string(255)
#  thumbnail   :string(255)
#  size        :integer
#  duration    :integer
#  state       :string(255)
#  type        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class Video < ActiveRecord::Base
  
  attr_accessible :file, :file_cache, :thumbnail
  uniquify :token, :chars => ('a'..'z').to_a + ('0'..'9').to_a
  mount_uploader :file, VideoUploader
  mount_uploader :thumbnail, ThumbnailUploader
  
  # ================
  # = Associations =
  # ================
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :type, :presence => true, :inclusion => { :in => %w[VideoOriginal VideoFormat] }
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_name, :set_size, :set_duration, :if => Proc.new { |v| v.file && (v.file_changed? || v.new_record?) }
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    before_transition :pending => :active, :do => [:set_name, :set_size, :set_duration]
    
    event(:activate)   { transition :pending => :active }
    event(:deactivate) { transition :active => :pending }
  end
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def set_size
    # TODO: Replace with real implementation
    write_attribute(:size, rand(100_000_000))
  end
  
  def set_duration
    # TODO: Replace with real implementation
    write_attribute(:duration, rand(7200))
  end
  
end
