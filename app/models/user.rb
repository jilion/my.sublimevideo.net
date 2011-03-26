class User < ActiveRecord::Base
  require 'user/credit_card'

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :lockable, :invitable

  # Mail template
  liquid_methods :email, :first_name, :last_name, :full_name

  attr_accessor :terms_and_conditions, :use, :current_password
  attr_accessible :first_name, :last_name, :email, :remember_me, :password, :current_password, :postal_code, :country,
                  :use_personal, :use_company, :use_clients,
                  :company_name, :company_url, :company_job_title, :company_employees, :company_videos_served,
                  :newsletter, :terms_and_conditions
  # Credit card
  attr_accessible :cc_update, :cc_type, :cc_full_name, :cc_number, :cc_expire_on, :cc_verification_value

  uniquify :cc_alias, :chars => Array('a'..'z') + Array('0'..'9')

  # ================
  # = Associations =
  # ================

  has_many :sites
  has_many :invoices, :through => :sites

  has_one :last_invoice, :through => :sites, :source => :invoices, :order => :created_at.desc

  # ===============
  # = Validations =
  # ===============

  validates :email, :presence => true, :email_uniqueness => true, :format => { :with => Devise.email_regexp }, :allow_blank => true

  with_options :if => :password_required? do |v|
    v.validates_presence_of :password, :on => :create
    v.validates_length_of   :password, :within => Devise.password_length, :allow_blank => true
  end

  validates :first_name,  :presence => true
  validates :last_name,   :presence => true
  validates :postal_code, :presence => true
  validates :country,     :presence => true
  validates :company_url, :hostname => true, :allow_blank => true
  validates :terms_and_conditions, :acceptance => { :accept => "1" }, :on => :create

  validate :validates_credit_card_attributes # in user/credit_card
  validate :validates_current_password

  # =============
  # = Callbacks =
  # =============

  before_save  :set_password
  before_save  :keep_some_credit_card_info # in user/credit_card
  after_update :update_email_on_zendesk, :charge_failed_invoices
  after_save   :newsletter_subscription

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :active do
    event(:suspend)        { transition :active => :suspended }
    event(:unsuspend)      { transition :suspended => :active }
    event(:archive)        { transition all => :archived }

    before_transition :on => :suspend, :do => :suspend_sites
    after_transition  :on => :suspend, :do => :send_account_suspended_email

    before_transition :on => :unsuspend, :do => :unsuspend_sites
    after_transition  :on => :unsuspend, :do => :send_account_unsuspended_email

    before_transition :on => :archive, :do => [:set_archived_at, :archive_sites]
    after_transition  :on => :archive, :do => :send_account_archived_email
  end

  # ==========
  # = Scopes =
  # ==========

  scope :billable,                lambda { scoped.merge(Site.billable) }
  scope :not_billable,            lambda { includes(:sites).where("(#{Site.billable.select("COUNT(sites.id)").where("sites.user_id = users.id").to_sql}) = 0") }
  scope :active_and_billable,     lambda { active.billable }
  scope :active_and_not_billable, lambda { active.not_billable }

  # credit_card scopes
  scope :without_cc, where(:cc_type => nil, :cc_last_digits => nil)
  scope :with_cc,    where(:cc_type.ne => nil, :cc_last_digits.ne => nil)

  # admin
  scope :enthusiast,        where(:enthusiast_id.ne => nil)
  scope :invited,           where(:invitation_token.ne => nil)
  scope :beta,              where(:invitation_token => nil)
  scope :active,            where(:state => 'active')
  scope :use_personal,      where(:use_personal => true)
  scope :use_company,       where(:use_company => true)
  scope :use_clients,       where(:use_clients => true)
  scope :created_between,   lambda { |start_date, end_date| where(:created_at.gte => start_date, :created_at.lt => end_date) }
  scope :signed_in_between, lambda { |start_date, end_date| where(:current_sign_in_at.gte => start_date, :current_sign_in_at.lt => end_date) }

  # sort
  scope :by_name_or_email,   lambda { |way = 'asc'| order(:first_name.send(way), :email.send(way)) }
  scope :by_sites_last_30_days_billable_player_hits_total_count,  lambda { |way = 'desc'|
    joins(:sites).group(User.column_names.map { |c| "\"users\".\"#{c}\"" }.join(', ')).order("SUM(sites.last_30_days_main_player_hits_total_count) + SUM(sites.last_30_days_extra_player_hits_total_count) #{way}")
  }
  scope :by_last_invoiced_amount,  lambda { |way = 'desc'| order(:last_invoiced_amount.send(way)) }
  scope :by_total_invoiced_amount, lambda { |way = 'desc'| order(:total_invoiced_amount.send(way)) }
  scope :by_beta,                  lambda { |way = 'desc'| order(:invitation_token.send(way)) }
  scope :by_date,                  lambda { |way = 'desc'| order(:created_at.send(way)) }

  # search
  def self.search(q)
    joins(:sites).
    where(:lower.func(:email).matches % :lower.func("%#{q}%") |
          :lower.func(:first_name).matches % :lower.func("%#{q}%") |
          :lower.func(:last_name).matches % :lower.func("%#{q}%") |
          :lower.func(:hostname).matches % :lower.func("%#{q}%") |
          :lower.func(:dev_hostnames).matches % :lower.func("%#{q}%")).select("DISTINCT users.id, users.*")
  end

  # =================
  # = Class Methods =
  # =================

  # Devise overriding
  # avoid the "not active yet" flash message to be displayed for archived users!
  def self.find_for_authentication(conditions={})
    conditions[:state.ne] = 'archived'
    super
  end

  def self.suspend(user_id)
    user = find(user_id)
    user.suspend!
  end

  def self.unsuspend(user_id)
    user = find(user_id)
    user.unsuspend!
  end

  # ====================
  # = Instance Methods =
  # ====================

  # Devise overriding
  def password=(new_password)
    @password = new_password
    # setted in #set_password
  end

  def email=(email)
    write_attribute(:email, email.try(:downcase))
  end

  # Devise overriding
  # allow suspended user to login (devise)
  def active?
    %w[active suspended].include?(state) && invitation_token.nil?
  end

  def get_discount?
    # TODO!!!!!!!!!!!!!!!!!!!!!!!!!!
  end

  def have_beta_sites?
    sites.any? { |site| site.in_beta_plan? }
  end

  def full_name
    first_name.to_s + ' ' + last_name.to_s
  end
  
  def support
    sites.active.map { |s| s.plan.support }.include?("priority") ? "priority" : "standard"
  end

private

  # validate
  def validates_current_password
    if !new_record? && ((state_changed? && archived?) || @password.present? || email_changed?) && errors.empty?
      if current_password.blank?
        self.errors.add(:current_password, :blank)
      elsif !valid_password?(current_password)
        self.errors.add(:current_password, :invalid)
      end
    end
  end

  # before_transition :on => :suspend
  def suspend_sites
    sites.billable.map(&:suspend)
  end

  # after_transition :on => :suspend
  def send_account_suspended_email
    UserMailer.account_suspended(self).deliver!
  end

  # before_transition :on => :unsuspend
  def unsuspend_sites
    sites.map(&:unsuspend)
  end

  # after_transition :on => :unsuspend
  def send_account_unsuspended_email
    UserMailer.account_unsuspended(self).deliver!
  end

  # before_transition :on => :archive
  def set_archived_at
    self.archived_at = Time.now.utc
  end
  def archive_sites
    sites.each do |site|
      site.without_password_validation { site.archive }
    end
  end

  # after_transition :on => :archive
  def send_account_archived_email
    UserMailer.account_archived(self).deliver!
  end

  # before_save
  def set_password
    if @password.present?
      self.password_salt = self.class.password_salt
      self.encrypted_password = password_digest(@password)
      @password = nil
    end
  end

  # after_save
  def newsletter_subscription
    if newsletter? && email_changed?
      CampaignMonitor.delay.unsubscribe(email_was) if email_was.present?
      CampaignMonitor.delay.subscribe(self)
    end
  end

  # after_update
  def update_email_on_zendesk
    if zendesk_id.present? && email_changed?
      Zendesk.delay(:priority => 25).put("/users/#{zendesk_id}.xml", :user => { :email => email })
    end
  end
  def charge_failed_invoices
    if cc_updated_at_changed? && invoices.failed.present?
      Transaction.delay(:priority => 2).charge_open_and_failed_invoices_by_user_id(id)
    end
  end

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
#  cc_type               :string(255)
#  cc_last_digits        :string(255)
#  cc_expire_on          :date
#  cc_updated_at         :datetime
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
#  cc_alias              :string(255)
#  archived_at           :datetime
#  newsletter            :boolean         default(TRUE)
#  last_invoiced_amount  :integer         default(0)
#  total_invoiced_amount :integer         default(0)
#
# Indexes
#
#  index_users_on_cc_alias               (cc_alias) UNIQUE
#  index_users_on_confirmation_token     (confirmation_token) UNIQUE
#  index_users_on_created_at             (created_at)
#  index_users_on_current_sign_in_at     (current_sign_in_at)
#  index_users_on_email_and_archived_at  (email,archived_at) UNIQUE
#  index_users_on_last_invoiced_amount   (last_invoiced_amount)
#  index_users_on_reset_password_token   (reset_password_token) UNIQUE
#  index_users_on_total_invoiced_amount  (total_invoiced_amount)
#

