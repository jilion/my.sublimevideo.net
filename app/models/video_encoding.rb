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
  
  attr_accessor :encoding_status
  
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
  
  scope :encoding,     where(:state => 'encoding')
  scope :active,       where(:state => 'active')
  scope :suspended,    where(:state => 'suspended')
  scope :with_profile, lambda { |profile| joins(:profile_version).where(["video_profile_versions.video_profile_id = ?", profile.id]) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :video,           :presence => true
  validates :profile_version, :presence => true
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    before_transition :on => :pandize, :do => :create_panda_encoding_and_set_info
    after_transition  :on => :pandize, :do => :delay_check_panda_encoding_status
    
    before_transition :on => :activate, :do => :deliver_video_active, :if => :all_first_encodings_complete?
    before_transition :on => :activate, :do => [:set_file, :set_encoding_info, :set_video_thumbnail]
    after_transition  :on => :activate, :do => [:deprecate_encodings, :delete_panda_encoding, :conform_to_video_state]
    
    before_transition :failed => :deprecated, :do => :delete_panda_encoding
    
    before_transition :on => :suspend, :do => :block_video
    
    before_transition :on => :unsuspend, :do => :unblock_video
    
    before_transition :on => :archive, :do => :remove_file!
    before_transition :encoding => :archived, :do => [:set_encoding_info, :delete_panda_encoding]
    
    event(:pandize)   { transition :pending => :encoding }
    event(:fail)      { transition [:pending, :encoding] => :failed }
    event(:activate)  { transition :encoding => :active }
    event(:deprecate) { transition [:active, :failed] => :deprecated }
    event(:suspend)   { transition :active => :suspended }
    event(:unsuspend) { transition :suspended => :active }
    event(:archive)   { transition [:pending, :encoding, :failed, :active, :deprecated, :suspended] => :archived }
    
    state(:encoding) do
      validates :panda_encoding_id, :presence => true
      validates :extname, :presence => true
      validates :width, :presence => true
      validates :height, :presence => true
    end
    
    state(:active) do
      validates :encoding_status, :inclusion => { :in => %w[success] }, :if => proc { |e| e.state_was == 'encoding' }
      validates :file_size, :presence => true
      validates :started_encoding_at, :presence => true
      validates :encoding_time, :presence => true
    end
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
    profile.extname[1..-1] # '.mp4' => 'mp4'
  end
  
  def first_encoding?
    encoding? && !file.present?
  end
  
  def all_first_encodings_complete?
    !file.present? && video.encodings.where(:id.ne => id).all? { |e| e.active? }
  end
  
protected
  
  # before_transition (pandize)
  def create_panda_encoding_and_set_info
    encoding_info = Transcoder.post(:encoding, { :video_id => video.panda_video_id, :profile_id => profile_version.panda_profile_id })
    
    if encoding_info.key? :error
      HoptoadNotifier.notify("VideoEncoding (#{id}) panda encoding creation error: #{encoding_info[:message]}")
      fail
    else
      self.panda_encoding_id = encoding_info[:id]
      self.extname           = encoding_info[:extname]
      self.width             = encoding_info[:width]
      self.height            = encoding_info[:height]
    end
  end
  
  # after_transition (pandize)
  def delay_check_panda_encoding_status
    delay(:priority => 10, :run_at => 15.minutes.from_now).check_panda_encoding_status
  end
  
  def check_panda_encoding_status
    unless active?
      encoding_info = Transcoder.get(:encoding, panda_encoding_id)
      if encoding_info[:status] != 'failed'
        delay_check_panda_encoding_status
      else
        HoptoadNotifier.notify("VideoEncoding (#{id}) panda encoding is failed.")
        fail
      end
    end
  end
  
  # before_transition (activate)
  def deliver_video_active
    VideoMailer.video_active(self.video).deliver
  end
  
  # before_transition (activate)
  def set_file
    self.remote_file_url = "#{self.class.panda_s3_url}/#{panda_encoding_id}#{extname}"
  end
  
  # before_transition (activate) / before_transition (encoding => archived)
  def set_encoding_info
    encoding_info = Transcoder.get(:encoding, panda_encoding_id)
    self.file_size           = encoding_info[:file_size]
    self.started_encoding_at = encoding_info[:started_encoding_at].try(:to_time)
    self.encoding_time       = encoding_info[:encoding_time]
    self.encoding_status     = encoding_info[:status]
  end
  
  # before_transition (activate)
  def set_video_thumbnail
    if profile.thumbnailable?
      self.video.remote_thumbnail_url = "#{self.class.panda_s3_url}/#{panda_encoding_id}_4.jpg"
      self.video.save!
    end
  end
  
  # after_transition (activate)
  def deprecate_encodings
    video.encodings.with_profile(profile).where(:state => %w[active failed], :id.ne => id).map(&:deprecate)
  end
  
  # after_transition (activate)
  def conform_to_video_state
    suspend if video.suspended?
  end
  
  # after_transition (activate) / before_transition (encoding => archived)
  def delete_panda_encoding
    Transcoder.delete(:encoding, panda_encoding_id)
  end
  
  # before_transition (suspend)
  def block_video
    # should set the READ right to NOBODY (or OWNER if it's enough)on the file
    # but maybe it'll be on the entire user's subdomain?
  end
  
  # before_transition (unsuspend)
  def unblock_video
    # should set the READ right to WORLD
  end
  
end