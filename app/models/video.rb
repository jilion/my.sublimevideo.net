# == Schema Information
#
# Table name: videos
#
#  id                :integer         not null, primary key
#  user_id           :integer
#  title             :string(255)
#  token             :string(255)
#  state             :string(255)
#  thumbnail         :string(255)
#  hits_cache        :integer         default(0)
#  bandwidth_cache   :integer         default(0)
#  panda_video_id    :string(255)
#  original_filename :string(255)
#  video_codec       :string(255)
#  audio_codec       :string(255)
#  extname           :string(255)
#  file_size         :integer
#  duration          :integer
#  width             :integer
#  height            :integer
#  fps               :integer
#  archived_at       :datetime
#  created_at        :datetime
#  updated_at        :datetime
#

class Video < ActiveRecord::Base
  
  attr_accessible :panda_video_id, :title, :file, :thumbnail
  uniquify :token, :chars => ('a'..'z').to_a + ('0'..'9').to_a
  
  mount_uploader :file,      VideoUploader
  mount_uploader :thumbnail, ThumbnailUploader
  
  cattr_accessor :per_page
  self.per_page = 6
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
  has_many   :encodings, :class_name => 'VideoEncoding'
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :by_date, lambda { |way| order("created_at #{way || 'desc'}") }
  scope :by_name, lambda { |way| order("name #{way || 'asc'}")        }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,           :presence => true
  validates :panda_video_id, :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    event(:pandize)    { transition :pending => :encodings }
    
    event(:suspend)    { transition [:pending, :encodings] => :encodings }
    event(:unsuspend)  { transition :encodings => :encodings }
    event(:archive)    { transition [:pending, :encodings] => :archived }
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.profiles
    # VideoProfile.
    Panda.get("/profiles.json")
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def all_encodings_active?
    encodings.all? { |e| e.active? }
  end
  
  def total_size
    size + encodings.sum(:size)
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
  
  def purge_video_files
    CDN.purge("/v/#{token}/#{panda_id}#{extname}")
    formats.each { |f| CDN.purge("/v/#{f.token}/#{f.panda_id}.#{f.extname}") }
  end
  
  def in_progress?
    pending? || inactive?
  end
  
  def container
    extname.gsub('.', '')
  end
  
protected
  
  # before_create
  def set_infos
    video_info    = Panda.get("/videos/#{video_panda_id}.json")
    self.name     = video_info['original_filename'].sub(File.extname(video_info['original_filename']), '').titleize.strip
    self.codec    = video_info['video_codec']
    self.extname  = video_info['extname']
    self.size     = video_info['file_size'].to_i
    self.duration = video_info['duration'].to_i
    self.width    = video_info['width'].to_i
    self.height   = video_info['height'].to_i
  end
  
  # after_create => after :pandaize
  def encode # create/add_formats
    Video.profiles.each do |profile|
      encoding_response = Panda.post("/encodings.json", { :video_id => panda_id, :profile_id => profile['id'] })
      encoding_response['title'] = profile['title']
      Video::Format.create_with_encoding_response(self, encoding_response)
    end
  end
  
  def set_archived_at
    self.archived_at = Time.now.utc
  end
  
end