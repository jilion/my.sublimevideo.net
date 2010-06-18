# == Schema Information
#
# Table name: video_encodings
#
#  id                       :integer         not null, primary key
#  video_id                 :integer
#  video_profile_version_id :integer
#  state                    :string(255)
#  file                     :string(255)
#  panda_encoding_id        :string(255)
#  started_encoding_at      :datetime
#  encoding_time            :integer
#  extname                  :string(255)
#  file_size                :integer
#  width                    :integer
#  height                   :integer
#  created_at               :datetime
#  updated_at               :datetime
#

class VideoEncoding < ActiveRecord::Base
  
  attr_accessor :encoding_ok
  
  mount_uploader :file, VideoUploader
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :video
  belongs_to :profile_version, :class_name => "VideoProfileVersion", :foreign_key => "video_profile_version_id"
  delegate   :profile, :to => :profile_version
  0
  # ==========
  # = Scopes =
  # ==========
  
  scope :pending,      where(:state => 'pending')
  scope :encoding,     where(:state => 'encoding')
  scope :active,       where(:state => 'active')
  scope :suspended,    where(:state => 'suspended')
  scope :with_profile, lambda { |profile| joins(:profile_version).where(["video_profile_versions.video_profile_id = ?", profile.id]) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :video,           :presence => true
  validates :profile_version, :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    before_transition :on => :activate, :do => [:set_file, :set_video_thumbnail, :deprecate_encodings]
    after_transition  :on => :activate, :do => [:delete_panda_encoding, :conform_to_video_state]
    
    before_transition :failed => :deprecated, :do => :delete_panda_encoding
    
    before_transition :on => :suspend, :do => :block_video
    
    before_transition :on => :unsuspend, :do => :unblock_video
    
    before_transition :on => :archive, :do => :remove_video_file!
    before_transition :encoding => :archived, :do => [:populate_information, :delete_panda_encoding]
    
    after_transition :on => [:suspend, :archive], :do => :purge_video
    
    event(:pandize) do
      transition [:pending, :active] => :encoding, :if => :panda_encoding_created?
      transition [:pending, :active] => :failed
      
      transition :failed => :encoding, :if => :retry_encoding_succeeded?
    end
    event(:fail)      { transition [:pending, :encoding] => :failed }
    event(:activate)  { transition :encoding => :active, :if => :panda_encoding_complete? }
    event(:deprecate) { transition [:active, :failed] => :deprecated }
    event(:suspend)   { transition :active => :suspended }
    event(:unsuspend) { transition :suspended => :active }
    event(:archive)   { transition [:pending, :encoding, :failed, :active, :deprecated, :suspended] => :archived }
  end
  
  # ============================
  # = State Machine Conditions =
  # ============================
  # pandize [:pending, :active] => :encoding
  def panda_encoding_created?
    create_panda_encoding
  end
  
  # pandize :failed => :encoding
  def retry_encoding_succeeded?
    unless video.suspended?
      if panda_encoding_id?
        encoding_info = Transcoder.retry(:encoding, panda_encoding_id)
        encoding_info[:status] != 'failed'
      else
        create_panda_encoding
      end
    else
      false
    end
  end
  
  # activate :encoding => :active
  def panda_encoding_complete?
    populate_information[:status] == 'success'
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.panda_s3_url
    @@panda_s3_url ||= "http://s3.amazonaws.com/" + Transcoder.get(:cloud, PandaConfig.cloud_id)[:s3_videos_bucket]
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def type
    profile.extname[1..-1]
  end
  
  def first_encoding?
    encoding? && !file.present?
  end
  
  def create_panda_encoding
    params        = { :video_id => video.panda_video_id, :profile_id => profile_version.panda_profile_id }
    encoding_info = Transcoder.post(:encoding, params)
    self.panda_encoding_id = encoding_info[:id]
    self.extname           = encoding_info[:extname]
    self.width             = encoding_info[:width]
    self.height            = encoding_info[:height]
    encoding_info[:status] != 'failed'
  end
  
  def populate_information
    encoding_info = Transcoder.get(:encoding, panda_encoding_id)
    self.file_size           = encoding_info[:file_size].to_i unless encoding_info[:file_size].nil?
    self.started_encoding_at = encoding_info[:started_encoding_at].to_time unless encoding_info[:started_encoding_at].nil?
    self.encoding_time       = encoding_info[:encoding_time].to_i unless encoding_info[:encoding_time].nil?
    encoding_info
  end
  
  # ======================================
  # = before_transition :on => :activate =
  # ======================================
  def set_file
    self.remote_file_url = "#{self.class.panda_s3_url}/#{panda_encoding_id}#{extname}"
  end
  def set_video_thumbnail
    if profile.thumbnailable?
      self.video.remote_thumbnail_url = "#{self.class.panda_s3_url}/#{panda_encoding_id}_4.jpg"
      self.video.save!
    end
  end
  def deprecate_encodings
    video.encodings.with_profile(profile).where(:state => %w[active failed]).map(&:deprecate)
  end
  
  # =====================================
  # = after_transition :on => :activate =
  # =====================================
  def conform_to_video_state
    suspend if video.suspended?
  end
  
  # ================================================================================
  # = after_transition :on => :activate & before_transition :encoding => :archived =
  # ================================================================================
  def delete_panda_encoding
    Transcoder.delete(:encoding, panda_encoding_id) if panda_encoding_id?
  end
  
  # =====================================
  # = before_transition :on => :suspend =
  # =====================================
  def block_video
    # should set the READ right to NOBODY (or OWNER if it's enough)on the file
    # but maybe it'll be on the entire user's subdomain?
  end
  
  # =======================================
  # = before_transition :on => :unsuspend =
  # =======================================
  def unblock_video
    # should set the READ right to WORLD
  end
  
  # =====================================
  # = before_transition :on => :archive =
  # =====================================
  def remove_video_file!
    remove_file!
  rescue => ex
    HoptoadNotifier.notify(ex)
  end
  
  # =================================================
  # = before_transition :on => [:suspend, :archive] =
  # =================================================
  def purge_video
    VoxcastCDN.purge("/v/#{video.token}/#{video.name}#{profile.name}#{extname}") if file.present?
  end
  
end