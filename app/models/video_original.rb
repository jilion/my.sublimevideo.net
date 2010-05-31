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
  
  after_create :encode
  
  # =================
  # = State Machine =
  # =================
  
  state_machine do
    event(:activate) { transition any => :active, :if => :all_formats_active? }
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.profiles
    # Change this to something smater...
    Rails.env.production? ? JSON[Panda.get("/profiles.json")] : []
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def all_formats_active?
    formats.all? { |f| f.active? }
  end
  
  def deactivate
    super
    formats.map(&:deactivate)
  end
  
  def total_size
    size + formats.map(&:size).sum
  end
  
protected
  
  # after_create
  def encode
    self.class.profiles.each do |profile|
      encoding_response = JSON[Panda.post("/encodings.json", { :video_id => panda_id, :profile_id => profile['id'] })]
      formats.create(:panda_id => encoding_response['id'], :name => encoding_response['extname'][1..-1])
    end
  end
  
end
