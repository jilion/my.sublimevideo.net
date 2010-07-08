# == Schema Information
#
# Table name: video_profile_versions
#
#  id               :integer         not null, primary key
#  video_profile_id :integer
#  panda_profile_id :string(255)
#  state            :string(255)
#  note             :text
#  created_at       :datetime
#  updated_at       :datetime
#

class VideoProfileVersion < ActiveRecord::Base
  
  attr_accessor :width, :height, :command
  attr_accessible :profile, :width, :height, :command, :note
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :profile, :class_name => "VideoProfile", :foreign_key => "video_profile_id"
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :active,       where(:state => 'active')
  scope :experimental, where(:state => 'experimental')
  scope :with_profile, lambda { |profile| where(:video_profile_id => profile.id) }
  scope :use_webm,     lambda { |use_webm_bool| joins(:profile).where("video_profiles.extname NOT IN('#{"webm" unless use_webm_bool}')") }
  scope :dimensions_less_than, lambda { |width, height| joins(:profile).where(["? >= video_profiles.min_width OR ? >= video_profiles.min_height", width, height]) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :profile,                  :presence => true
  validates :width, :height, :command, :presence => true, :on => :create
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :pending do
    before_transition :on => :pandize, :do => :create_panda_profile_and_set_info
    
    after_transition  :on => :activate, :do => :deprecate_profile_versions
    
    event(:pandize)   { transition :pending      => :experimental }
    event(:activate)  { transition :experimental => :active }
    event(:deprecate) { transition [:active, :experimental] => :deprecated }
    
    state(:experimental) do
      validates :panda_profile_id, :presence => true
    end
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def rank
    profile.versions.order(:created_at.asc).index(self) + 1
  end
  
protected
  
  # before_transition (pandize)
  def create_panda_profile_and_set_info
    profile_info = Transcoder.post(:profile, { :title => "#{profile.title} ##{profile.versions.size + 1}", :extname => ".#{profile.extname}", :width => width, :height => height, :command => command })
    
    if profile_info.key? :error
      HoptoadNotifier.notify(:error_message => "VideoProfileVersion (#{id}) panda profile creation error: #{profile_info[:message]}")
    else
      self.panda_profile_id = profile_info[:id]
    end
  end
  
  # after_transition (activate)
  def deprecate_profile_versions
    profile.versions.with_profile(profile).where(:state => %w[active experimental], :id.ne => id).map(&:deprecate)
  end
  
end