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
  
  scope :by_date,     lambda { |way| order("videos.created_at #{way || 'desc'}") }
  scope :by_title,    lambda { |way| order("videos.title #{way || 'asc'}") }
  scope :displayable, where("videos.state NOT IN ('archived')")
  
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
    before_transition :on => :pandize, :do => :set_encoding_info
    after_transition  :on => :pandize, :do => :create_encodings
    
    before_transition :on => :activate, :do => :activate_encodings
    after_transition  :on => :activate, :do => :deliver_video_active, :if => :active?
    
    before_transition :on => :suspend, :do => :suspend_encodings
    
    before_transition :on => :unsuspend, :do => :unsuspend_encodings
    
    before_transition :on => :archive, :do => [:set_archived_at, :archive_encodings]
    after_transition  :on => :archive, :do => [:remove_video, :remove_thumbnail!]
    
    event(:pandize)   { transition :pending => :encodings }
    event(:activate)  { transition :encodings => :encodings }
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
    encodings? && encodings.any? { |e| e.first_encoding? }
  end
  
  def active?
    encodings? && encodings.all? { |e| e.active? }
  end
  
  def error?
    encodings? && encodings.any? { |e| e.failed? }
  end
  
  def hd?
    (width? && width >= 720) || (height? && height >= 1280)
  end
  
  def name
    original_filename && extname ? original_filename.sub(".#{extname}", '') : ''
  end
  
  def total_size
    encodings.active.inject([file_size]){ |memo,e| memo << e.file_size }.compact.sum
  end
  
protected
  
  # before_transition (pandize)
  def set_encoding_info
    video_info             = Transcoder.get(:video, panda_video_id)
    self.original_filename = video_info[:original_filename].strip
    self.video_codec       = video_info[:video_codec]
    self.audio_codec       = video_info[:audio_codec]
    self.extname           = video_info[:extname].gsub('.','') if video_info[:extname]
    self.file_size         = video_info[:file_size]
    self.duration          = video_info[:duration]
    self.width             = video_info[:width]
    self.height            = video_info[:height]
    self.fps               = video_info[:fps]
    self.title             = original_filename.sub(".#{extname}", '').titleize
  end
  
  # after_transition (pandize)
  def create_encodings
    VideoProfileVersion.active.each do |profile_version|
      encoding = encodings.build(:profile_version => profile_version)
      encoding.save!
      encoding.delay(:priority => 5).pandize!
    end
  end
  
  # before_transition (activate)
  def activate_encodings
    encodings.encoding.map(&:activate)
  end
  
  # after_transition (activate)
  def deliver_video_active
    VideoMailer.video_active(self).deliver
  end
  
  # before_transition (suspend)
  def suspend_encodings
    encodings.active.map(&:suspend)
  end
  
  # before_transition (unsuspend)
  def unsuspend_encodings
    encodings.suspended.map(&:unsuspend)
  end
  
  # before_transition (archive)
  def set_archived_at
    self.archived_at = Time.now.utc
  end
  def archive_encodings
    encodings.each { |e| e.delay(:priority => 10).archive }
  end
  def remove_video
    Transcoder.delay(:priority => 7).delete(:video, panda_video_id)
  end
  
end