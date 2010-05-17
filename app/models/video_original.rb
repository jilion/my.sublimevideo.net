# == Schema Information
#
# Table name: videos
#
#  id          :integer         not null, primary key
#  user_id     :integer
#  original_id :integer
#  name        :string(255)
#  file        :string(255)
#  thumbnail   :string(255)
#  size        :integer
#  duration    :integer
#  state       :string(255)
#  type        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class VideoOriginal < Video
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
  has_many :formats, :class_name => 'VideoFormat', :foreign_key => 'original_id'
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user, :presence => true
  
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
  
  def set_name
    write_attribute(:name, File.basename(file.url, File.extname(file.url)).titleize)
  end
  
  def total_size
    size + formats.sum(:size)
  end
  
end