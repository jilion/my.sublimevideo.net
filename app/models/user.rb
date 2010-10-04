class User < ActiveRecord::Base
  include Trial
  include LimitAlert
  include CreditCard
  
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable, :invitable
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 100
  
  attr_accessor :terms_and_conditions
  attr_accessible :first_name, :last_name, :email, :remember_me, :password, :postal_code, :country,
                  :use_personal, :use_company, :use_clients,
                  :company_name, :company_url, :company_job_title, :company_employees, :company_videos_served,
                  :terms_and_conditions
  # Trial
  attr_accessible :limit_alert_amount
  # Credit Card
  attr_accessible :cc_update, :cc_type, :cc_full_name, :cc_number, :cc_expire_on, :cc_verification_value
  
  # ================
  # = Associations =
  # ================
  
  has_many :sites
  has_many :invoices, :autosave => false, :validate => false
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :in_trial,        where(:trial_ended_at => nil)
  scope :not_in_trial,    where(:trial_ended_at.ne => nil)
  scope :limit_alertable, where(:limit_alert_amount.gt => 0, :limit_alert_email_sent_at => nil)
  scope :without_cc,      where(:cc_type => nil, :cc_last_digits => nil)
  scope :with_cc,         where(:cc_type.ne => nil, :cc_last_digits.ne => nil)
  
  # admin
  scope :enthusiast,      where(:enthusiast_id.ne => nil)
  scope :beta,            where(:invitation_token => nil)
  scope :with_activity,   includes(:sites).where(:sites => { :player_hits_cache.gte => 1 })
  scope :use_personal,    where(:use_personal => true)
  scope :use_company,     where(:use_company => true)
  scope :use_clients,     where(:use_clients => true)
  # sort
  scope :by_name_or_email, lambda { |way| order(:first_name.send(way || 'desc'), :email.send(way || 'desc')) }
  scope :by_beta,          lambda { |way| order(:invitation_token.send(way || 'desc')) }
  scope :by_player_hits,   lambda { |way| joins(:sites).group("users.#{User.first.attributes.keys.join(', users.')}").order("SUM(sites.player_hits_cache) #{way}") }
  scope :by_traffic,       lambda { |way| joins(:sites).group("users.#{User.first.attributes.keys.join(', users.')}").order("SUM(sites.traffic_voxcast_cache + sites.traffic_s3_cache) #{way}") }
  scope :by_date,          lambda { |way| order(:created_at.send(way || 'desc')) }
  # search
  scope :search, lambda { |q| includes(:sites).where(["LOWER(users.email) LIKE LOWER(?) OR LOWER(users.first_name) LIKE LOWER(?) OR LOWER(users.last_name) LIKE LOWER(?) OR LOWER(sites.hostname) LIKE LOWER(?) OR LOWER(sites.dev_hostnames) LIKE LOWER(?)", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"]) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :postal_code, :presence => true
  validates :country, :presence => true
  validates :terms_and_conditions, :acceptance => { :accept => "1" }, :on => :create
  validates :company_url, :hostname_uniqueness => true, :allow_blank => true
  validate :validates_credit_card_attributes # in user/credit_card
  validate :validates_use_presence_on_invitation_update
  validate :validates_company_fields_on_invitation_update
  validate :validates_terms_and_conditions_on_invitation_update
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :set_next_invoiced_on
  before_save :store_credit_card, :keep_some_credit_card_info # in user/credit_card
  before_save :clear_limit_alert_email_sent_at_when_limit_alert_amount_is_augmented # in user/limit_alert
  after_update :update_email_on_zendesk
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :active do
    before_transition :on => :suspend, :do => :suspend_sites
    before_transition :on => :unsuspend, :do => :unsuspend_sites
    
    event(:suspend)   { transition :active => :suspended }
    event(:unsuspend) { transition :suspended => :active }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # allow suspended user to login (devise)
  def active?
    %w[active suspended].include?(state) && invitation_token.nil?
  end
  
  def welcome?
    sites.empty? && !credit_card?
  end
  
  def full_name
    first_name.to_s + ' ' + last_name.to_s
  end
  
  def email=(email)
    write_attribute(:email, email.try(:downcase))
  end
  
private
  
  # validate
  def validates_use_presence_on_invitation_update
    if invited? && !use_personal && !use_company && !use_clients
      self.errors.add(:use, "Please check at least one option.")
    end
  end
  
  # validate
  def validates_company_fields_on_invitation_update
    if invited? && use_company
      self.errors.add(:company_name, :blank) unless company_name.present?
      self.errors.add(:company_url, :blank) unless company_url.present?
      self.errors.add(:company_job_title, :blank) unless company_job_title.present?
      self.errors.add(:company_employees, :blank) unless company_employees.present?
      self.errors.add(:company_videos_served, :blank) unless company_videos_served.present?
    end
  end
  
  # validate
  def validates_terms_and_conditions_on_invitation_update
    Rails.logger.debug terms_and_conditions.inspect
    if invited? && terms_and_conditions != "1"
      self.errors.add(:terms_and_conditions, :accepted)
    end
  end
  
  # before_create
  def set_next_invoiced_on
    self.next_invoiced_on ||= Time.now.utc.to_date + 1.month
  end
  
  # before_transition (suspend)
  def suspend_sites
    sites.map(&:suspend)
  end
  
  # before_transition (unsuspend)
  def unsuspend_sites
    sites.map(&:unsuspend)
  end
  
  # after_update
  def update_email_on_zendesk
    if zendesk_id.present? && email_changed?
      Zendesk.delay(:priority => 25).put("/users/#{zendesk_id}.xml", :user => { :email => email })
    end
  end
  
protected
  
  # Allow User.invite to assign enthusiast_id
  def mass_assignment_authorizer
    new_record? ? (self.class.active_authorizer + ["enthusiast_id"]) : super
  end
  
end
# == Schema Information
#
# Table name: users
#
#  id                                    :integer         not null, primary key
#  state                                 :string(255)
#  email                                 :string(255)     default(""), not null
#  encrypted_password                    :string(128)     default(""), not null
#  password_salt                         :string(255)     default(""), not null
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
#  zendesk_id                            :integer
#  enthusiast_id                         :integer
#  first_name                            :string(255)
#  last_name                             :string(255)
#  postal_code                           :string(255)
#  country                               :string(255)
#  use_personal                          :boolean
#  use_company                           :boolean
#  use_clients                           :boolean
#  company_name                          :string(255)
#  company_url                           :string(255)
#  company_job_title                     :string(255)
#  company_employees                     :string(255)
#  company_videos_served                 :string(255)
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

