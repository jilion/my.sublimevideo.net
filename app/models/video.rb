# == Schema Information
#
# Table name: videos
#
#  id                      :integer         not null, primary key
#  user_id                 :integer
#  title                   :string(255)
#  token                   :string(255)
#  state                   :string(255)
#  posterframe             :string(255)
#  hits_cache              :integer         default(0)
#  bandwidth_s3_cache      :integer         default(0)
#  bandwidth_us_cache      :integer         default(0)
#  bandwidth_eu_cache      :integer         default(0)
#  bandwidth_as_cache      :integer         default(0)
#  bandwidth_jp_cache      :integer         default(0)
#  bandwidth_unknown_cache :integer         default(0)
#  requests_s3_cache       :integer         default(0)
#  requests_us_cache       :integer         default(0)
#  requests_eu_cache       :integer         default(0)
#  requests_as_cache       :integer         default(0)
#  requests_jp_cache       :integer         default(0)
#  requests_unknown_cache  :integer         default(0)
#  panda_video_id          :string(255)
#  original_filename       :string(255)
#  video_codec             :string(255)
#  audio_codec             :string(255)
#  extname                 :string(255)
#  file_size               :integer
#  duration                :integer
#  width                   :integer
#  height                  :integer
#  fps                     :integer
#  archived_at             :datetime
#  created_at              :datetime
#  updated_at              :datetime
#

class Video < ActiveRecord::Base
  
  attr_accessible :title
  uniquify :token, :chars => Array('a'..'z') + Array('0'..'9')
  
  mount_uploader :posterframe, PosterframeUploader
  
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
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    before_transition :on => :pandize, :do => :set_encoding_info
    after_transition  :on => :pandize, :do => [:create_encodings, :delay_check_panda_encodings_status]
    
    before_transition :on => :activate, :do => :activate_encodings
    after_transition  :on => :activate, :do => :deliver_video_active
    
    before_transition :on => :suspend, :do => [:suspend_encodings, :suspend_posterframe]
    
    before_transition :on => :unsuspend, :do => [:unsuspend_encodings, :unsuspend_posterframe]
    
    before_transition :on => :archive, :do => [:set_archived_at, :archive_encodings]
    after_transition  :on => :archive, :do => [:remove_video, :remove_posterframe!]
    
    event(:pandize)   { transition :pending => :encodings }
    event(:activate)  { transition :encodings => :encodings }
    event(:suspend)   { transition [:pending, :encodings] => :suspended }
    event(:unsuspend) { transition :suspended => :encodings }
    event(:archive)   { transition [:pending, :encodings, :suspended] => :archived }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def sanitize_filename(filename, ext=extname)
    filename[0...-ext.size].strip.downcase.gsub(/[^a-z\d]/, '_').squeeze('_').chomp('_').reverse.chomp('_').reverse + ".#{ext}"
  end
  
  def titleize_filename(filename, ext=extname)
    title = filename.sub(".#{ext}", '').gsub(/[-_.]/, ' ')
    title.split(' ').map do |word|
      word =~ /^([a-z][A-Z]\w*|[0-9A-Z]+)$/ ? word : word.titleize
    end.join(' ')
  end
  
  def first_processing?(reload = false)
    encodings? && encodings(reload).any? { |e| e.first_processing? }
  end
  
  def reprocessing?(reload = false)
    encodings? && encodings(reload).any? { |e| e.reprocessing? }
  end
  
  def processing?(reload = false)
    encodings? && encodings(reload).any? { |e| e.processing? }
  end
  
  def active?(reload = false)
    encodings? && encodings(reload).all? { |e| e.active? }
  end
  
  def error?(reload = false)
    encodings? && encodings(reload).any? { |e| e.failed? }
  end
  
  # def hd?
  #   (width? && width >= 720) || (height? && height >= 1280)
  # end
  
  def name
    original_filename && extname ? original_filename.sub(".#{extname}", '') : ''
  end
  
  def encodings_size
    encodings.not_deprecated.all.sum { |e| e.file_size.to_i }
  end
  
  def total_size
    file_size.to_i + encodings_size
  end
  
  def check_panda_encodings_status
    if processing?
      encodings_info = Transcoder.get([:video, :encodings], panda_video_id)
      if encodings_info.all? { |encoding_info| encoding_info[:status] == 'success' }
        self.activate
      elsif encodings_info.any? { |encoding_info| encoding_info[:status] == 'processing' }
        delay_check_panda_encodings_status
      else
        encodings_info.each do |encoding_info|
          encoding = encodings.find_by_panda_encoding_id(encoding_info[:id])
          if encoding.processing?
            case encoding_info[:status]
            when 'success'
              encoding.activate
            when 'fail'
              encoding.fail
              HoptoadNotifier.notify("VideoEncoding (#{encoding.id}) panda encoding (panda_encoding_id: #{encoding.panda_encoding_id}) is failed.")
            end
          end
        end
      end
    end
  end
  
  def height_from_width(width)
    (width.to_i*self.height)/self.width
  end
  
protected
  
  # before_transition (pandize)
  def set_encoding_info
    video_info             = Transcoder.get(:video, panda_video_id)
    self.extname           = video_info[:extname].try(:gsub, '.', '')
    self.original_filename = sanitize_filename(video_info[:original_filename])
    self.video_codec       = video_info[:video_codec]
    self.audio_codec       = video_info[:audio_codec]
    self.file_size         = video_info[:file_size]
    self.duration          = video_info[:duration]
    self.width             = video_info[:width]
    self.height            = video_info[:height]
    self.fps               = video_info[:fps]
    self.title             = titleize_filename(video_info[:original_filename])
  end
  
  # after_transition (pandize)
  def create_encodings
    profile_versions = VideoProfileVersion.active.dimensions_less_than(width, height).use_webm(user.use_webm?).all
    if user.use_webm?
      webm_profile_versions = profile_versions.select{ |pv| pv.profile.extname == 'webm' }
      if webm_profile_versions.size > 1 # delete the SD version only if it's not the only webm possible
        webm_sd_profiles = webm_profile_versions.select{ |pv| pv.profile.name == '_sd' }
        profile_versions.delete(webm_sd_profiles[0]) if webm_sd_profiles.present?
      end
    end
    profile_versions.each do |profile_version|
      encoding = encodings.create(:profile_version => profile_version)
      encoding.delay(:priority => 5).pandize!
    end
  end
  def delay_check_panda_encodings_status
    delay(:priority => 9, :run_at => 5.minutes.from_now).check_panda_encodings_status
  end
  
  # before_transition (activate)
  def activate_encodings
    encodings.processing.map(&:activate)
  end
  
  # after_transition (activate)
  def deliver_video_active
    VideoMailer.video_active(self).deliver if active?(true)
  end
  
  # before_transition (suspend)
  def suspend_encodings
    encodings.active.map(&:suspend)
  end
  def suspend_posterframe
    S3.videos_bucket.key(posterfame.path).put(nil, 'private') if Rails.env.production? && S3.videos_bucket.key(posterfame.path).exists?
  end
  
  # before_transition (unsuspend)
  def unsuspend_encodings
    encodings.suspended.map(&:unsuspend)
  end
  def unsuspend_posterframe
    S3.videos_bucket.key(posterfame.path).put(nil, 'public-read') if Rails.env.production? && S3.videos_bucket.key(posterfame.path).exists?
  end
  
  # before_transition (archive)
  def set_archived_at
    self.archived_at = Time.now.utc
  end
  def archive_encodings
    encodings.not_deprecated.each { |e| e.delay(:priority => 8).archive }
  end
  def remove_video
    Transcoder.delay(:priority => 7).delete(:video, panda_video_id)
  end
  
end
