# == Schema Information
#
# Table name: video_profile_versions
#
#  id               :integer         not null, primary key
#  video_profile_id :integer
#  panda_profile_id :string(255)
#  state            :string(255)
#  num              :integer
#  note             :text
#  created_at       :datetime
#  updated_at       :datetime
#

class VideoProfileVersion < ActiveRecord::Base
  
  attr_accessible :num, :note
  
  attr_accessor :width, :height, :command
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :profile, :class_name => "VideoProfile", :foreign_key => "video_profile_id"
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :active,       where(:state => 'active')
  scope :experimental, where(:state => 'experimental')
  
  # ===============
  # = Validations =
  # ===============
  
  validates :profile,                  :presence => true
  validates :width, :height, :command, :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    event(:pandize)  { transition :pending => :experimental, :if => :create_panda_profile }
    event(:activate) { transition :experimental => :active                                }
  end
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # before_transition :on => :pandize
  def create_panda_profile
    params   = { :title => "#{profile.title} ##{profile.versions.size + 1}", :extname => profile.extname, :width => width, :height => height, :command => command }
    response = Transcoder.post(:profile, params)
    if response.key? :id
      self.panda_profile_id = response[:id]
      true
    else
      false
    end
  end
  
end