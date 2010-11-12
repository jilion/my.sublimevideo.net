class User < ActiveRecord::Base
  include CreditCard
  
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable, :invitable
  
  # Pagination
  cattr_accessor :per_page
  self.per_page = 100
  
  # Mail template
  liquid_methods :email, :first_name, :last_name, :full_name
  
  attr_accessor :terms_and_conditions
  attr_accessible :first_name, :last_name, :email, :remember_me, :password, :postal_code, :country,
                  :use_personal, :use_company, :use_clients,
                  :company_name, :company_url, :company_job_title, :company_employees, :company_videos_served,
                  :terms_and_conditions
  # Credit Card
  attr_accessible :cc_update, :cc_type, :cc_full_name, :cc_number, :cc_expire_on, :cc_verification_value
  
  # ================
  # = Associations =
  # ================
  
  has_many :sites
  has_many :invoices
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :without_cc,      where(:cc_type => nil, :cc_last_digits => nil)
  scope :with_cc,         where(:cc_type.ne => nil, :cc_last_digits.ne => nil)
  
  # invoice
  scope :billable_on,     lambda { |date = Time.now.utc.to_date| includes(:sites).where({ :next_invoiced_on => date.to_date } | ({ :next_invoiced_on => nil } & { :sites => { :activated_at.gte => date.to_date - Billing.trial_days, :activated_at.lt => date.to_date - Billing.trial_days + 1.day } })) }
  
  # admin
  scope :enthusiast,      where(:enthusiast_id.ne => nil)
  scope :invited,         where(:invitation_token.ne => nil)
  scope :beta,            where(:invitation_token => nil)
  scope :use_personal,    where(:use_personal => true)
  scope :use_company,     where(:use_company => true)
  scope :use_clients,     where(:use_clients => true)
  # sort
  scope :by_name_or_email, lambda { |way = 'asc'| order("#{User.quoted_table_name}.first_name #{way}, #{User.quoted_table_name}.email #{way}") }
  scope :by_beta,          lambda { |way = 'desc'| order("#{User.quoted_table_name}.invitation_token #{way}") }
  scope :by_date,          lambda { |way = 'desc'| order("#{User.quoted_table_name}.created_at #{way}") }
  
  # search
  scope :search, lambda { |q| includes(:sites).where(["LOWER(#{User.quoted_table_name}.email) LIKE LOWER(?) OR LOWER(#{User.quoted_table_name}.first_name) LIKE LOWER(?) OR LOWER(#{User.quoted_table_name}.last_name) LIKE LOWER(?) OR LOWER(#{Site.quoted_table_name}.hostname) LIKE LOWER(?) OR LOWER(#{Site.quoted_table_name}.dev_hostnames) LIKE LOWER(?)", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"]) }
  
  # ===============
  # = Validations =
  # ===============
  
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :postal_code, :presence => true
  validates :country, :presence => true
  validates :terms_and_conditions, :acceptance => { :accept => "1" }, :on => :create
  validates :company_url, :hostname => true, :allow_blank => true
  validate :validates_credit_card_attributes # in user/credit_card
  validate :validates_use_presence, :on => :create
  validate :validates_company_fields, :on => :create
  
  # =============
  # = Callbacks =
  # =============
  
  before_save   :store_credit_card, :keep_some_credit_card_info # in user/credit_card
  after_update  :update_email_on_zendesk
  
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
  
  def full_name
    first_name.to_s + ' ' + last_name.to_s
  end
  
  def email=(email)
    write_attribute(:email, email.try(:downcase))
  end
  
private
  
  # validate
  def validates_use_presence
    if !use_personal && !use_company && !use_clients
      self.errors.add(:use, "Please check at least one option")
    end
  end
  
  # validate
  def validates_company_fields
    if use_company
      self.errors.add(:company_name, :blank) unless company_name.present?
      self.errors.add(:company_url, :blank) unless company_url.present?
      self.errors.add(:company_job_title, :blank) unless company_job_title.present?
      self.errors.add(:company_employees, :blank) unless company_employees.present?
      self.errors.add(:company_videos_served, :blank) unless company_videos_served.present?
    end
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
    if zendesk_id.present? && previous_changes.keys.include?("email")
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
#  id                    :integer         not null, primary key
#  state                 :string(255)
#  email                 :string(255)     default(""), not null
#  encrypted_password    :string(128)     default(""), not null
#  password_salt         :string(255)     default(""), not null
#  confirmation_token    :string(255)
#  confirmed_at          :datetime
#  confirmation_sent_at  :datetime
#  reset_password_token  :string(255)
#  remember_token        :string(255)
#  remember_created_at   :datetime
#  sign_in_count         :integer         default(0)
#  current_sign_in_at    :datetime
#  last_sign_in_at       :datetime
#  current_sign_in_ip    :string(255)
#  last_sign_in_ip       :string(255)
#  failed_attempts       :integer         default(0)
#  locked_at             :datetime
#  invoices_count        :integer         default(0)
#  last_invoiced_on      :date
#  next_invoiced_on      :date
#  cc_type               :string(255)
#  cc_last_digits        :integer
#  cc_expire_on          :date
#  cc_updated_at         :datetime
#  video_settings        :text
#  created_at            :datetime
#  updated_at            :datetime
#  invitation_token      :string(20)
#  invitation_sent_at    :datetime
#  zendesk_id            :integer
#  enthusiast_id         :integer
#  first_name            :string(255)
#  last_name             :string(255)
#  postal_code           :string(255)
#  country               :string(255)
#  use_personal          :boolean
#  use_company           :boolean
#  use_clients           :boolean
#  company_name          :string(255)
#  company_url           :string(255)
#  company_job_title     :string(255)
#  company_employees     :string(255)
#  company_videos_served :string(255)
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

