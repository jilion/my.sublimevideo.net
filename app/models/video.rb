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
  
  attr_accessible :title
  uniquify :token, :chars => ('a'..'z').to_a + ('0'..'9').to_a
  
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
  scope :by_title, lambda { |way| order("title #{way || 'asc'}")        }
  
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
    before_transition :on => :pandize, :do => :set_video_information
    after_transition  :on => :pandize, :do => :create_encodings
    
    before_transition :on => :suspend, :do => :suspend_encodings
    
    before_transition :on => :unsuspend, :do => :unsuspend_encodings
    
    before_transition :on => :archive, :do => [:set_archived_at, :archive_encodings]
    after_transition  :on => :archive, :do => :remove_video_and_thumbnail!
    
    after_transition :on => [:suspend, :archive], :do => :purge_thumbnail
    
    event(:pandize)   { transition :pending => :encodings }
    event(:suspend)   { transition [:pending, :encodings] => :suspended }
    event(:unsuspend) { transition :suspended => :encodings }
    event(:archive)   { transition [:pending, :encodings, :suspended] => :archived }
  end
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def encoding?
    self.encodings.any? { |e| e.encoding? }
  end
  
  def active?
    self.encodings.present? && self.encodings.all? { |e| e.active? }
  end
  
  def failed?
    self.encodings.any? { |e| e.failed? }
  end
  
  def hd?
    (width? && width >= 720) || (height? && height >= 1280)
  end
  
  def name
    original_filename ? original_filename.sub(extname, '') : ''
  end
  
  def total_size
    file_size + self.encodings.sum(:file_size)
  end
  
protected
  
  # =====================================
  # = before_transition :on => :pandize =
  # =====================================
  def set_video_information
    video_info             = Transcoder.get(:video, panda_video_id)
    self.original_filename = video_info[:original_filename].strip
    self.video_codec       = video_info[:video_codec]
    self.audio_codec       = video_info[:audio_codec]
    self.extname           = video_info[:extname]
    self.file_size         = video_info[:file_size].to_i
    self.duration          = video_info[:duration].to_i
    self.width             = video_info[:width].to_i
    self.height            = video_info[:height].to_i
    self.fps               = video_info[:fps].to_i
    self.title             = original_filename.sub(extname, '').titleize
  end
  
  # ====================================
  # = after_transition :on => :pandize =
  # ====================================
  def create_encodings
    VideoProfile.active.each do |profile|
      encoding = self.encodings.build(:profile_version => profile.active_version)
      encoding.save!
      encoding.delay(:priority => 5).pandize
    end
  end
  
  # =====================================
  # = before_transition :on => :suspend =
  # =====================================
  def suspend_encodings
    encodings.active.map(&:suspend)
  end
  
  # =======================================
  # = before_transition :on => :unsuspend =
  # =======================================
  def unsuspend_encodings
    encodings.suspended.map(&:unsuspend)
  end
  
  # =====================================
  # = before_transition :on => :archive =
  # =====================================
  def set_archived_at
    self.archived_at = Time.now.utc
  end
  def archive_encodings
    self.encodings.active.each { |e| e.delay(:priority => 10).archive }
  end
  def remove_video_and_thumbnail!
    Transcoder.delay(:priority => 6).delete(:video, panda_video_id)
    remove_thumbnail!
  end
  
  # ================================================
  # = after_transition :on => [:archive, :suspend] =
  # ================================================
  def purge_thumbnail
    VoxcastCDN.purge("/v/#{token}/posterframe.jpg") if thumbnail.present?
  end
  
end