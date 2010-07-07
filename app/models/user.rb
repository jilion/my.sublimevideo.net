# == Schema Information
#
# Table name: users
#
#  id                                    :integer         not null, primary key
#  state                                 :string(255)
#  email                                 :string(255)     default(""), not null
#  encrypted_password                    :string(128)     default(""), not null
#  password_salt                         :string(255)     default(""), not null
#  full_name                             :string(255)
#  confirmation_token                    :string(255)
#  confirmed_at                          :datetime
#  confirmation_sent_at                  :datetime
#  reset_password_token                  :string(255)
#  remember_token                        :string(255)
#  remember_created_at                   :datetime
#  sign_in_count                         :integer         default(0)
#  current_sign_in_at                    :datetime
#  last_sign_in_at                       :datetime
#  current_sign_in_ip                    :string(255)
#  last_sign_in_ip                       :string(255)
#  failed_attempts                       :integer         default(0)
#  locked_at                             :datetime
#  invoices_count                        :integer         default(0)
#  last_invoiced_on                      :date
#  next_invoiced_on                      :date
#  trial_ended_at                        :datetime
#  trial_usage_information_email_sent_at :datetime
#  trial_usage_warning_email_sent_at     :datetime
#  limit_alert_amount                    :integer         default(0)
#  limit_alert_email_sent_at             :datetime
#  cc_type                               :string(255)
#  cc_last_digits                        :integer
#  cc_expire_on                          :date
#  cc_updated_at                         :datetime
#  video_settings                        :text
#  created_at                            :datetime
#  updated_at                            :datetime
#  invitation_token                      :string(20)
#  invitation_sent_at                    :datetime
#

class User < ActiveRecord::Base
  include Trial
  include LimitAlert
  include CreditCard
  include VideoSettings
  
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable, :invitable
  
  attr_accessor :terms_and_conditions
  attr_accessible :full_name, :email, :remember_me, :password, :terms_and_conditions
  # Trial
  attr_accessible :limit_alert_amount
  # Credit Card
  attr_accessible :cc_update, :cc_type, :cc_full_name, :cc_number, :cc_expire_on, :cc_verification_value
  # Video Settings
  attr_accessible :video_settings
  serialize :video_settings
  
  # ================
  # = Associations =
  # ================
  
  has_many :sites
  has_many :videos
  has_many :invoices, :autosave => false, :validate => false
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :in_trial,        where(:trial_ended_at => nil)
  scope :limit_alertable, where(:limit_alert_amount.gt => 0, :limit_alert_email_sent_at => nil)
  scope :without_cc,      where(:cc_type => nil, :cc_last_digits => nil)
  
  # ===============
  # = Validations =
  # ===============
  
  validates :full_name,        :presence => true
  validates :email,            :presence => true, :uniqueness => true
  validates :terms_and_conditions, :acceptance => { :accept => "1" }, :on => :create
  validate :validates_credit_card_attributes # in user/credit_card
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_next_invoiced_on
  before_save :set_default_video_settings # in user/video_settings
  before_save :clear_limit_alert_email_sent_at_when_limit_alert_amount_is_augmented # in user/limit_alert
  before_save :store_credit_card, :keep_some_credit_card_info # in user/credit_card
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :active do
    before_transition :on => :suspend, :do => [:suspend_sites, :suspend_videos]
    before_transition :on => :unsuspend, :do => [:unsuspend_sites, :unsuspend_videos]
    
    event(:suspend)   { transition :active => :suspended }
    event(:unsuspend) { transition :suspended => :active }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # allow suspended user to login (devise)
  def active?
    %w[active suspended].include?(state)
  end
  
  def welcome?
    sites.empty? && !credit_card?
  end
  
private
  
  # before_create
  def set_next_invoiced_on
    self.next_invoiced_on ||= Time.now.utc.to_date + 1.month
  end
  
  # before_transition (suspend)
  def suspend_sites
    sites.map(&:suspend)
  end
  def suspend_videos
    videos.map(&:suspend)
  end
  
  # before_transition (unsuspend)
  def unsuspend_sites
    sites.map(&:unsuspend)
  end
  def unsuspend_videos
    videos.map(&:unsuspend)
  end
  
end
