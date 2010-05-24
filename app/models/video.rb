# == Schema Information
#
# Table name: videos
#
#  id          :integer         not null, primary key
#  panda_id    :string(255)
#  user_id     :integer
#  original_id :integer
#  name        :string(255)
#  token       :string(255)
#  file        :string(255)
#  thumbnail   :string(255)
#  codec       :string(255)
#  container   :string(255)
#  size        :integer
#  duration    :integer
#  width       :integer
#  height      :integer
#  state       :string(255)
#  type        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class Video < ActiveRecord::Base
  
  attr_accessible :panda_id, :name, :file, :file_cache, :thumbnail, :codec, :container, :size, :duration, :width, :height
  uniquify :token, :chars => ('a'..'z').to_a + ('0'..'9').to_a
  mount_uploader :file, VideoUploader
  
  cattr_accessor :per_page
  self.per_page = 6
  
  # ================
  # = Associations =
  # ================
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :by_date, lambda { |way| order("created_at #{way || 'desc'}") }
  scope :by_name, lambda { |way| order("name #{way || 'asc'}")        }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :type, :presence => true, :inclusion => { :in => %w[VideoOriginal VideoFormat] }
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_size
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    event(:activate)   { transition :pending => :active }
    event(:deactivate) { transition :active => :pending }
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.panda_profiles_ids
    '123456, 654321' # TODO To be changed, and maybe move to config/panda.yml
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # before_create
  def set_size
    # TODO: Replace with real implementation
    write_attribute(:size, rand(100_000_000))
  end
  
end
