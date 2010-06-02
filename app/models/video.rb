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
  
  validates :type,     :presence => true, :inclusion => { :in => %w[VideoOriginal VideoFormat] }
  validates :panda_id, :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_infos
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    event(:deactivate) { transition :active => :pending }
    event(:fail)       { transition any => :failed }
  end
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # before_create
  def set_infos
    if panda_id
      if Rails.env.production? # Change this to something smarter...
        set_name
        video_infos    = JSON[Panda.get("/videos/#{panda_id}.json")]
        self.codec     = video_infos['codec']
        self.container = video_infos['container']
        self.codec     = video_infos['codec']
        self.size      = video_infos['size']
        self.duration  = video_infos['duration']
        self.width     = video_infos['width']
        self.height    = video_infos['height']
        self.state     = video_infos['status'] == 'success' ? 'active' : video_infos['status']
      end
    else
      fail
    end
  end
  
  def set_name
    name = File.basename(file.url, File.extname(file.url)).titleize.strip
    write_attribute(:name, name.blank? ? "Untitled - #{Time.now.strftime("%m/%d/%Y %I:%M%p")}" : name)
  end
  
end
