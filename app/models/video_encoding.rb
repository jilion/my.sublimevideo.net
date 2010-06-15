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
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :pending, where(:state => 'pending')
  
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
    before_transition :on => :activate, :do => [:populate_information, :set_file, :set_video_thumbnail]
    after_transition  :on => :activate, :do => :delete_panda_encoding
    
    event(:pandize) do
      transition [:pending, :active] => :encoding, :if => :encoding_ok?
      transition :failed             => :encoding, :if => :retry_encoding_ok?
      transition [:pending, :active] => :failed
    end
    
    event(:activate)  { transition :encoding => :active }
    event(:fail)      { transition [:pending, :encoding] => :failed }
    
    event(:suspend)   { transition [:pending, :encoding, :failed, :active] => :suspended }
    event(:unsuspend) do
      transition :suspended => :active, :if => :file_present?
      transition :suspended => :encoding
    end
    event(:archive)   { transition [:pending, :encoding, :failed, :active] => :archived }
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.panda_s3_url
    @@panda_s3_url ||= "http://s3.amazonaws.com/" + Panda.get("/clouds/#{PandaConfig.cloud_id}.json")["s3_videos_bucket"]
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def first_encoding?
    encoding? && !file.present?
  end
  
  def encoding_ok?
    create_panda_encoding
  end
  
  def retry_encoding_ok?
    if panda_encoding_id?
      # response = Transcoder.retry(:encoding, params)
    else
      create_panda_encoding
    end
  end
  
  def create_panda_encoding
    params   = { :video_id => video.panda_video_id, :profile_id => profile_version.panda_profile_id }
    response = Transcoder.post(:encoding, params)
    if response.key?(:id)
      self.panda_encoding_id = response[:id]
      self.extname           = response[:extname]
      self.width             = response[:width]
      self.height            = response[:height]
      response[:status] != 'failed'
    else
      false
    end
  end
  
  # before_transition :on => :activate
  def populate_information
    encoding_info            = Transcoder.get(:encoding, panda_encoding_id)
    self.file_size           = encoding_info[:file_size].to_i
    self.started_encoding_at = encoding_info[:started_encoding_at].to_time
    self.encoding_time       = encoding_info[:encoding_time].to_i
  end
  
  # before_transition :on => :activate
  def set_file
    self.remote_file_url = "#{self.class.panda_s3_url}/#{panda_encoding_id}#{extname}"
  end
  
  # before_transition :on => :activate
  def set_video_thumbnail
    self.video.remote_thumbnail_url = "#{self.class.panda_s3_url}/#{panda_encoding_id}_4.jpg" if profile.thumbnailable?
    self.video.save!
  end
  
  # after_transition :on => :activate
  def delete_panda_encoding
    response = Transcoder.delete(:encoding, panda_encoding_id)
    raise "Couldn't delete encoding ##{panda_encoding_id}" unless response[:deleted]
  end
  
end