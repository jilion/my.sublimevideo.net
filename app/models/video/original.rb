# == Schema Information
#
# Table name: videos
#
#  id          :integer         not null, primary key
#  user_id     :integer
#  original_id :integer
#  panda_id    :string(255)
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

class Video::Original < Video
  
  mount_uploader :thumbnail, ThumbnailUploader
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
  has_many   :formats, :class_name => 'Video::Format', :foreign_key => 'original_id', :dependent => :destroy
  
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
  
  before_create :set_infos
  after_create  :encode
  
  # =================
  # = State Machine =
  # =================
  
  state_machine do
    event(:activate) { transition any => :active, :if => :all_formats_active? }
    after_transition :on => :activate do |video, transition|
      video.populate_formats_information
    end
  end
  
  # =================
  # = Class Methods =
  # =================
  
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
  
  # after_transition :on => :activate
  def populate_formats_information
    Panda.get("/videos/#{panda_id}/encodings.json").each do |format_info|
      next unless f = formats.find_by_panda_id(format_info['id'])
      # f.codec    = format_info['video_codec'] # not returned by the API...
      Rails.logger.debug "format_info: #{format_info.inspect}"
      f.size = format_info['file_size'].to_i
      f.save
    end
  end
  
protected
  
  # before_create
  def set_infos
    raise "Can't create a video without an id from Panda" unless panda_id.present?
    
    video_info     = Panda.get("/videos/#{panda_id}.json")
    self.name      = video_info['original_filename'].sub(File.extname(video_info['original_filename']), '').titleize.strip
    self.codec     = video_info['video_codec']
    self.container = video_info['extname'].gsub('.','')
    self.size      = video_info['file_size'].to_i
    self.duration  = video_info['duration'].to_i
    self.width     = video_info['width'].to_i
    self.height    = video_info['height'].to_i
  end
  
  # after_create
  def encode
    Video.profiles.each do |profile|
      encoding_response = Panda.post("/encodings.json", { :video_id => panda_id, :profile_id => profile['id'] })
      encoding_response['title'] = profile['title']
      Video::Format.create_with_encoding_response(self, encoding_response)
    end
  end
  
end
