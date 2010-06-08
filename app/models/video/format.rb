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

class Video::Format < Video
  
  # attr_accessible :original_id
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :original, :class_name => 'Video::Original'
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :pending, where(:state => 'pending')
  
  # ===============
  # = Validations =
  # ===============
  
  validates :original, :presence => true
  validates :name, :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine do
    event(:activate) { transition any => :active }
    after_transition :on => :activate do |video_format, transition|
      video_format.original.activate
    end
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.create_with_encoding_response(original, encoding_response)
    raise "Can't create a format without an id from Panda" unless encoding_response['id'].present?
    new_format           = original.formats.build
    new_format.panda_id  = encoding_response['id']
    new_format.name      = encoding_response['title']
    new_format.container = encoding_response['extname'].gsub('.','')
    new_format.width     = encoding_response['width'].to_i
    new_format.height    = encoding_response['height'].to_i
    new_format.size      = 0
    new_format.save!
    new_format.fail if encoding_response['status'] == 'fail'
    new_format
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
end
