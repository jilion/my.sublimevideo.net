# == Schema Information
#
# Table name: video_encodings
#
#  id                       :integer         not null, primary key
#  video_id                 :integer
#  video_profile_id         :integer
#  video_profile_version_id :integer
#  state                    :string(255)
#  file                     :string(255)
#  panda_encoding_id        :integer
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
  
  mount_uploader :file, VideoUploader
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :video
  belongs_to :profile, :class_name => "VideoProfile", :foreign_key => "video_profile_id"
  belongs_to :profile_version, :class_name => "VideoProfileVersion", :foreign_key => "video_profile_version_id"
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :pending, where(:state => 'pending')
  
  # ===============
  # = Validations =
  # ===============
  
  validates :video,           :presence => true
  validates :profile,         :presence => true
  validates :profile_version, :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  # before_save :set_blup
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    event(:pandize)   { transition [:pending, :failed, :active] => :encoding }
    event(:activate)  { transition :encoding => :active }
    event(:fail)      { transition :encoding => :failed }
    
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
  
  # def self.create_with_encoding_response(original, encoding_response)
  #   raise "Can't create a format without an id from Panda" unless encoding_response['id'].present?
  #   new_format           = original.formats.build
  #   new_format.panda_id  = encoding_response['id']
  #   new_format.name      = encoding_response['title']
  #   new_format.container = encoding_response['extname'].gsub('.','')
  #   new_format.width     = encoding_response['width'].to_i
  #   new_format.height    = encoding_response['height'].to_i
  #   new_format.size      = 0
  #   new_format.save!
  #   new_format.fail if encoding_response['status'] == 'fail'
  #   new_format
  # end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # after_transition :on => :activate
  # def populate_formats_information
  #   Panda.get("/videos/#{panda_id}/encodings.json").each do |format_info|
  #     next unless f = formats.find_by_panda_id(format_info['id'])
  #     # f.codec    = format_info['video_codec'] # not returned by the API...
  #     Rails.logger.debug "format_info: #{format_info.inspect}"
  #     f.size = format_info['file_size'].to_i
  #     f.save
  #   end
  # end
  
private
  
end