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
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :video
  belongs_to :video_profile
  belongs_to :video_profile_version
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :pending, where(:state => 'pending')
  
  # ===============
  # = Validations =
  # ===============
  
  validates :original, :presence => true
  validates :name,     :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  # before_save :set_blup
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    event(:pandize)    { transition [:pending, :failed, :active] => :encoding }
    event(:activate)   { transition :encoding => :active }
    event(:fail)       { transition :encoding => :failed }
    
    event(:suspend)    { transition [:pending, :encoding, :failed, :active] => :suspended }
    event(:unsuspend)  do
      transition :suspended => :active, :if => :file_present?
      transition :suspended => :encoding
    end
    event(:archive)    { transition [:pending, :encoding, :failed, :active] => :archived }
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
  
private
  
end