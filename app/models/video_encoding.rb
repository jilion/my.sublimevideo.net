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
  
  scope :processing,     where(:state => 'processing')
  scope :active,         where(:state => 'active')
  scope :suspended,      where(:state => 'suspended')
  scope :not_deprecated, where(:state.ne => 'deprecated')
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
    
    before_transition :on => :activate, :do => [:set_file, :set_file_added_at, :set_encoding_info, :set_video_posterframe]
    after_transition  :on => :activate, :do => [:deprecate_encodings, :delete_panda_encoding, :conform_to_video_state]
    
    before_transition :on => [:deprecate, :archive], :do => :set_file_removed_at
    before_transition :failed => :deprecated, :do => :delete_panda_encoding
    
    before_transition :on => :suspend, :do => :block_video
    
    before_transition :on => :unsuspend, :do => :unblock_video
    
    before_transition :on => :archive, :do => :remove_file!
    before_transition :processing => :archived, :do => :set_encoding_info
    after_transition  :processing => :archived, :do => :delete_panda_encoding
    
    event(:pandize)   { transition :pending => :processing }
    event(:fail)      { transition [:pending, :processing] => :failed }
    event(:activate)  { transition :processing => :active }
    event(:deprecate) { transition [:active, :failed] => :deprecated }
    event(:suspend)   { transition :active => :suspended }
    event(:unsuspend) { transition :suspended => :active }
    event(:archive)   { transition [:pending, :processing, :failed, :active, :deprecated, :suspended] => :archived }
    
    state(:processing) do
      validates :panda_encoding_id, :presence => true
      validates :extname, :presence => true
    end
    
    state(:active) do
      validates :encoding_status, :inclusion => { :in => %w[success] }, :if => proc { |e| e.state_was == 'processing' }
      validates :file_size, :presence => true
      validates :started_encoding_at, :presence => true
      validates :encoding_time, :presence => true
      validates :width, :presence => true
      validates :height, :presence => true
    end
  end
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def first_processing?
    processing? && !file.present?
  end
  
  def reprocessing?
    processing? && file.present?
  end
  
protected
  
  # before_transition (pandize)
  def create_panda_encoding_and_set_info
    encoding_info = Transcoder.post(:encoding, { :video_id => video.panda_video_id, :profile_id => profile_version.panda_profile_id })
    
    if encoding_info.key? :error
      HoptoadNotifier.notify("VideoEncoding (#{id}) panda encoding (panda_encoding_id: #{panda_encoding_id}) creation error: #{encoding_info[:message]}")
      fail
    else
      self.panda_encoding_id = encoding_info[:id]
      self.extname           = encoding_info[:extname].try(:gsub, '.', '')
    end
  end
  
  # before_transition (activate)
  def set_file
    
    # file_on_panda_bucket = Aws::S3::Key.create(S3.panda_bucket, "#{panda_encoding_id}.#{extname}")
    # file_on_video_bucket = Aws::S3::Key.create(S3.videos_bucket, "#{video.token}/#{video.name}#{profile.name}.#{extname}")
    # file_on_panda_bucket.copy(file_on_video_bucket)
    
    # self.write_attribute(:file, "#{video.token}/#{video.name}#{profile.name}.#{extname}")
    self.remote_file_url = "#{self.class.panda_s3_url}/#{panda_encoding_id}.#{extname}"
  end
  def set_file_added_at
    self.file_added_at = Time.now.utc
  end
  
  # before_transition (activate) / before_transition (processing => archived)
  def set_encoding_info
    encoding_info = Transcoder.get(:encoding, panda_encoding_id)
    self.file_size           = encoding_info[:file_size]
    self.started_encoding_at = encoding_info[:started_encoding_at].try(:to_time)
    self.encoding_time       = encoding_info[:encoding_time]
    self.encoding_status     = encoding_info[:status]
    self.width               = encoding_info[:width]
    self.height              = encoding_info[:height]
  end
  
  # before_transition (activate)
  def set_video_posterframe
    if !video.posterframe.present? && profile.posterframeable? && video.encodings.map(&:profile).select{ |p| p.posterframeable? && p.min_width > profile.min_width }.empty?
      video.set_posterframe_from_encoding(self)
      # self.video.remote_posterframe_url = "#{self.class.panda_s3_url}/#{panda_encoding_id}_4.jpg"
    end
  end
  
  # after_transition (activate)
  def deprecate_encodings
    video.encodings.with_profile(profile).where(:state => %w[active failed], :id.ne => id).map(&:deprecate!)
  end
  def conform_to_video_state
    suspend if video.suspended?
  end
  
  # after_transition (activate) / after_transition (processing => archived)
  def delete_panda_encoding
    Transcoder.delete(:encoding, panda_encoding_id)
  end
  
  # before_transition (suspend)
  def block_video
    S3.videos_bucket.key(file.path).put(nil, 'private') if Rails.env.production? && S3.videos_bucket.key(file.path).exists?
  end
  
  # before_transition (unsuspend)
  def unblock_video
    S3.videos_bucket.key(file.path).put(nil, 'public-read') if Rails.env.production? && S3.videos_bucket.key(file.path).exists?
  end
  
  # before_transition (deprecate) / (archive)
  def set_file_removed_at
    self.file_removed_at = Time.now.utc
  end
  
end