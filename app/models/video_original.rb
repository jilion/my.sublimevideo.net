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
#  state       :string(255)
#  type        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

class VideoOriginal < Video
  
  mount_uploader :thumbnail, ThumbnailUploader
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
  has_many   :formats, :class_name => 'VideoFormat', :foreign_key => 'original_id'
  
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
  
  before_create :set_name, :set_duration
  
  # =================
  # = State Machine =
  # =================
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # before_create
  def set_name
    name = File.basename(file.url, File.extname(file.url)).titleize.strip
    write_attribute(:name, name.blank? ? "Untitled - #{Time.now.strftime("%m/%d/%Y %I:%M%p")}" : name)
  end
  
  # before_create
  def set_duration
    # TODO: Replace with real implementation
    write_attribute(:duration, rand(7200))
  end
  
  def activate
    super
    formats.each { |f| f.activate }
  end
  
  def deactivate
    super
    formats.each { |f| f.deactivate }
  end
  
  def total_size
    size + formats.map(&:size).sum
  end
  
end
