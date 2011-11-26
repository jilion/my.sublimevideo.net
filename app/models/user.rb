class User < ActiveRecord::Base
  include UserModules::CreditCard
  include UserModules::Pusher
  include UserModules::Scope

  devise :database_authenticatable, :invitable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :lockable

  def self.cookie_domain
    ".sublimevideo.net"
  end

  # Mail template
  liquid_methods :email, :name

  attr_accessor :terms_and_conditions, :use, :current_password, :remote_ip
  attr_accessible :email, :name, :remember_me, :password, :current_password, :hidden_notice_ids,
                  :billing_name, :billing_address_1, :billing_address_2, :billing_postal_code, :billing_city, :billing_region, :billing_country,
                  :use_personal, :use_company, :use_clients,
                  :company_name, :company_url, :company_job_title, :company_employees, :company_videos_served,
                  :newsletter, :terms_and_conditions
  # Credit card
  # cc_register is a flag to indicate if the CC should be recorded or not
  attr_accessible :cc_register, :cc_brand, :cc_full_name, :cc_number, :cc_expiration_year, :cc_expiration_month, :cc_verification_value, :remote_ip

  serialize :hidden_notice_ids, Array

  uniquify :cc_alias, chars: Array('A'..'Z') + Array('0'..'9')

  # ================
  # = Associations =
  # ================

  belongs_to :enthusiast

  has_many :sites
  has_many :invoices, through: :sites
  has_one  :last_invoice, through: :sites, source: :invoices, order: :created_at.desc

  # API
  has_many :client_applications
  has_many :tokens, class_name: "OauthToken", order: :authorized_at.desc, include: [:client_application]

  # ===============
  # = Validations =
  # ===============

  validates :email, presence: true, email_uniqueness: true, format: { with: Devise.email_regexp }, allow_blank: true

  with_options if: :password_required? do |v|
    v.validates_presence_of :password, on: :create
    v.validates_length_of   :password, within: Devise.password_length, allow_blank: true
  end

  validates :name, presence: true
  validates :billing_country, presence: true, if: :billable?
  validates :billing_postal_code, length: { maximum: 20 }, allow_blank: true
  validates :company_url, hostname: true, allow_blank: true
  validates :terms_and_conditions, acceptance: { accept: "1" }, on: :create

  validate :validates_credit_card_attributes # in user/credit_card
  validate :validates_current_password

  # =============
  # = Callbacks =
  # =============

  before_save :set_password

  before_save :prepare_pending_credit_card, if: proc { |u| u.credit_card(true).valid? } # in user/credit_card

  after_save :register_credit_card_on_file, if: proc { |u| u.cc_register } # in user/credit_card
  after_save :newsletter_update

  after_update :zendesk_update

  # =================
  # = State Machine =
  # =================

  state_machine initial: :active do
    event(:suspend)   { transition active: :suspended }
    event(:unsuspend) { transition suspended: :active }
    event(:archive)   { transition [:active, :suspended] => :archived }

    state :archived do
      validate :prevent_archive_with_non_paid_invoices
    end

    before_transition on: :suspend, do: :suspend_sites
    after_transition  on: :suspend, do: :send_account_suspended_email

    before_transition on: :unsuspend, do: :unsuspend_sites
    after_transition  on: :unsuspend, do: :send_account_unsuspended_email

    before_transition on: :archive, do: [:set_archived_at, :archive_sites]
    after_transition  on: :archive, do: [:invalidate_tokens, :newsletter_unsubscribe, :send_account_archived_email]
  end

  # =================
  # = Class Methods =
  # =================

  # Devise overriding
  # avoid the "not active yet" flash message to be displayed for archived users!
  def self.find_for_authentication(conditions = {})
    where(conditions).where{state != 'archived'}.first
  end

  def update_tracked_fields!(request)
    # Don't update user when he's accessing the API
    if !request.params.key?(:oauth_token) &&
       (!request.headers.key?('HTTP_AUTHORIZATION') || !request.headers['HTTP_AUTHORIZATION'] =~ /OAuth/)
      super(request)
    end
  end

  def self.suspend(user_id)
    user = find(user_id)
    user.suspend
  end

  def self.unsuspend(user_id)
    user = find(user_id)
    user.unsuspend
  end

  # ====================
  # = Instance Methods =
  # ====================

  # Devise overriding
  def password=(new_password)
    @password = new_password
    # set in #set_password
  end

  def current_password=(new_current_password)
    @current_password = new_current_password.nil? ? nil : CGI::unescapeHTML(new_current_password)
  end

  def email=(email)
    write_attribute(:email, email.try(:downcase))
  end

  def notice_hidden?(id)
    hidden_notice_ids.map(&:to_s).include?(id.to_s)
  end

  # Devise overriding
  # allow suspended user to login (devise)
  def active_for_authentication?
    %w[active suspended].include?(state)
  end

  def beta?
    invitation_token.nil? && created_at < PublicLaunch.beta_transition_started_on.midnight
  end

  def vat?
    Vat.for_country?(billing_country)
  end

  def billing_address
    Snail.new(
      name:        billing_name.presence || name,
      line_1:      billing_address_1,
      line_2:      billing_address_2,
      postal_code: billing_postal_code,
      city:        billing_city,
      region:      billing_region,
      country:     billing_country? ? Country[billing_country.to_s].name : ''
    ).to_s
  end

  def billing_address_complete?
    [billing_address_1, billing_postal_code, billing_city, billing_country].all?(&:present?)
  end

  def more_info_incomplete?
    [billing_postal_code, billing_country, company_name, company_url, company_job_title, company_employees].any?(&:blank?) ||
    [use_personal, use_company, use_clients].all?(&:blank?) # one of these fields is enough
  end

  def support
    support_level = sites.active.max { |a, b| a.plan.support_level <=> b.plan.support_level }.try(:plan).try(:support_level) || 0

    Plan::SUPPORT_LEVELS[support_level]
  end

  def email_support?
    %w[email vip_email].include?(support)
  end

  def billable?
    sites.active.billable.any?
  end

  def archivable?
    sites.active.all? { |site| site.archivable? }
  end

  def skip_pwd
    @skip_password_validation = true
    result = yield
    @skip_password_validation = false
    result
  end

  def save_skip_pwd
    skip_pwd { self.save! }
  end

private

  # validate
  def validates_current_password
    return if @skip_password_validation

    if persisted? &&
      ((state_changed? && archived?) || @password.present? || email_changed?) &&
      errors.empty? &&
      # handle Devise password reset!!
      # at first, Devise call valid? and then reset_password_token is not nil so no problem, but then it clear reset_password_token so it's nil so the second check !reset_password_token_changed? is necessary!!!!!!
      (reset_password_token.nil? && !reset_password_token_changed?)
      if current_password.blank?
        self.errors.add(:current_password, :blank)
      elsif !valid_password?(current_password)
        self.errors.add(:current_password, :invalid)
      end
    end
  end

  # validate (archived state)
  def prevent_archive_with_non_paid_invoices
    unless archivable?
      self.errors.add(:base, :not_paid_invoices_prevent_archive, count: invoices.not_paid.count)
    end
  end

  # before_transition on: :suspend
  def suspend_sites
    sites.includes(:invoices).where(invoices: { state: 'failed' }).map(&:suspend)
  end

  # after_transition on: :suspend
  def send_account_suspended_email
    My::UserMailer.account_suspended(self).deliver!
  end

  # before_transition on: :unsuspend
  def unsuspend_sites
    sites.where(state: 'suspended').map(&:unsuspend)
  end

  # after_transition on: :unsuspend
  def send_account_unsuspended_email
    My::UserMailer.account_unsuspended(self).deliver!
  end

  # before_transition on: :archive
  def set_archived_at
    self.archived_at = Time.now.utc
  end
  def archive_sites
    sites.each do |site|
      site.skip_pwd { site.archive }
    end
  end

  # after_transition on: :archive
  def invalidate_tokens
    tokens.update_all(invalidated_at: Time.now.utc)
  end

  # after_transition on: :archive
  def newsletter_unsubscribe
    CampaignMonitor.delay.unsubscribe(self.email)
  end

  # after_transition on: :archive
  def send_account_archived_email
    My::UserMailer.account_archived(self).deliver!
  end

  # before_save
  def set_password
    if @password.present?
      self.encrypted_password = password_digest(@password)
      @password = nil
    end
  end

  # after_save
  def newsletter_update
    if newsletter_changed? || email_changed? || name_changed?
      if email_was.present?
        CampaignMonitor.delay.update(self)
        CampaignMonitor.delay(run_at: 30.seconds.from_now).unsubscribe(email) unless newsletter?
      elsif newsletter? # on sign-up
        CampaignMonitor.delay.subscribe(self)
      end
    end
  end

  # after_update
  def zendesk_update
    if zendesk_id.present? && (email_changed? || name_changed?)
      body = email_changed? ? "<email>#{email}</email>" : "<name>#{name}</name>"
      Zendesk.delay(priority: 25).put("/users/#{zendesk_id}.xml", "<user>#{body}<is-verified>true</is-verified></user>")
    end
  end

  # ===========================
  # = From Devise Validatable =
  # ===========================

  # Checks whether a password is needed or not. For validations only.
  # Passwords are always required if it's a new record, or if the password
  # or confirmation are being set somewhere.
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

end


# == Schema Information
#
# Table name: users
#
#  id                              :integer         not null, primary key
#  state                           :string(255)
#  email                           :string(255)     default(""), not null
#  encrypted_password              :string(128)     default(""), not null
#  password_salt                   :string(255)     default(""), not null
#  confirmation_token              :string(255)
#  confirmed_at                    :datetime
#  confirmation_sent_at            :datetime
#  reset_password_token            :string(255)
#  remember_created_at             :datetime
#  sign_in_count                   :integer         default(0)
#  current_sign_in_at              :datetime
#  last_sign_in_at                 :datetime
#  current_sign_in_ip              :string(255)
#  last_sign_in_ip                 :string(255)
#  failed_attempts                 :integer         default(0)
#  locked_at                       :datetime
#  cc_type                         :string(255)
#  cc_last_digits                  :string(255)
#  cc_expire_on                    :date
#  cc_updated_at                   :datetime
#  created_at                      :datetime
#  updated_at                      :datetime
#  invitation_token                :string(20)
#  invitation_sent_at              :datetime
#  zendesk_id                      :integer
#  enthusiast_id                   :integer
#  first_name                      :string(255)
#  last_name                       :string(255)
#  billing_postal_code             :string(255)
#  billing_country                 :string(255)
#  use_personal                    :boolean
#  use_company                     :boolean
#  use_clients                     :boolean
#  company_name                    :string(255)
#  company_url                     :string(255)
#  company_job_title               :string(255)
#  company_employees               :string(255)
#  company_videos_served           :string(255)
#  cc_alias                        :string(255)
#  pending_cc_type                 :string(255)
#  pending_cc_last_digits          :string(255)
#  pending_cc_expire_on            :date
#  pending_cc_updated_at           :datetime
#  archived_at                     :datetime
#  newsletter                      :boolean         default(TRUE)
#  last_invoiced_amount            :integer         default(0)
#  total_invoiced_amount           :integer         default(0)
#  balance                         :integer         default(0)
#  hidden_notice_ids               :text
#  name                            :string(255)
#  billing_name                    :string(255)
#  billing_address_1               :string(255)
#  billing_address_2               :string(255)
#  billing_city                    :string(255)
#  billing_region                  :string(255)
#  last_failed_cc_authorize_at     :datetime
#  last_failed_cc_authorize_status :integer
#  last_failed_cc_authorize_error  :string(255)
#  referrer_site_token             :string(255)
#  reset_password_sent_at          :datetime
#  remember_token                  :string(255)
#
# Indexes
#
#  index_users_on_cc_alias               (cc_alias) UNIQUE
#  index_users_on_confirmation_token     (confirmation_token) UNIQUE
#  index_users_on_created_at             (created_at)
#  index_users_on_current_sign_in_at     (current_sign_in_at)
#  index_users_on_email_and_archived_at  (email,archived_at) UNIQUE
#  index_users_on_last_invoiced_amount   (last_invoiced_amount)
#  index_users_on_referrer_site_token    (referrer_site_token)
#  index_users_on_reset_password_token   (reset_password_token) UNIQUE
#  index_users_on_total_invoiced_amount  (total_invoiced_amount)
#

