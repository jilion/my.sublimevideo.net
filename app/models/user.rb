require_dependency 'validators/email_uniqueness_validator'
require_dependency 'validators/hostname_validator'
require_dependency 'zendesk_wrapper'
require_dependency 'newsletter_manager'
require_dependency 'public_launch'
require_dependency 'vat'

class User < ActiveRecord::Base
  include UserModules::Activity
  include UserModules::CreditCard
  include UserModules::Pusher
  include UserModules::Scope

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :lockable

  def self.cookie_domain
    ".sublimevideo.net"
  end

  # Mail template
  liquid_methods :email, :name, :plan_title

  acts_as_taggable

  attr_accessor :terms_and_conditions, :use, :current_password, :remote_ip
  attr_accessible :email, :remember_me, :password, :current_password, :hidden_notice_ids,
                  :name, :postal_code, :country, :confirmation_comment,
                  :billing_name, :billing_address_1, :billing_address_2, :billing_postal_code, :billing_city, :billing_region, :billing_country,
                  :use_personal, :use_company, :use_clients,
                  :company_name, :company_url, :company_job_title, :company_employees, :company_videos_served,
                  :newsletter, :terms_and_conditions
  # Credit card
  # cc_register is a flag to indicate if the CC should be recorded or not
  attr_accessible :cc_register, :cc_brand, :cc_full_name, :cc_number, :cc_expiration_year, :cc_expiration_month, :cc_verification_value, :remote_ip

  serialize :hidden_notice_ids, Array
  serialize :early_access, Array

  uniquify :cc_alias, chars: Array('A'..'Z') + Array('0'..'9')

  # ================
  # = Associations =
  # ================

  belongs_to :enthusiast

  has_many :sites

  # Invoices
  has_many :invoices, through: :sites
  has_many :feedbacks

  def last_invoice
    @last_invoice ||= invoices.last
  end

  # Deals
  has_many :deal_activations

  # API
  has_many :client_applications
  has_many :tokens, class_name: "OauthToken", order: 'authorized_at DESC', include: [:client_application]

  # ===============
  # = Validations =
  # ===============

  validates :email, presence: true, email_uniqueness: true, format: { with: Devise.email_regexp }, allow_blank: true

  with_options if: :password_required? do |v|
    v.validates_presence_of :password, on: :create
    v.validates_length_of   :password, within: Devise.password_length, allow_blank: true
  end

  validates :postal_code, :billing_postal_code, length: { maximum: 20 }, allow_blank: true
  validates :company_url, hostname: true, allow_blank: true
  validates :terms_and_conditions, acceptance: { accept: "1" }, on: :create

  validate :validates_credit_card_attributes # in user/credit_card
  validate :validates_current_password

  # =============
  # = Callbacks =
  # =============

  before_save :set_password

  before_save :prepare_pending_credit_card, if: proc { |u| u.credit_card(true).valid? } # in user/credit_card

  after_create :send_welcome_email
  after_create :sync_newsletter, unless: :newsletter?

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

    before_transition on: :suspend, do: :suspend_sites
    after_transition  on: :suspend, do: :send_account_suspended_email

    before_transition on: :unsuspend, do: :unsuspend_sites
    after_transition  on: :unsuspend, do: :send_account_unsuspended_email

    before_transition on: :archive, do: [:set_archived_at, :invalidate_tokens, :archive_sites]
    after_transition  on: :archive, do: [:newsletter_unsubscribe, :send_account_archived_email]
  end

  # =================
  # = Class Methods =
  # =================

  # Devise overriding
  # avoid the "not active yet" flash message to be displayed for archived users!
  def self.find_for_authentication(conditions = {})
    where(conditions).where{ state != 'archived' }.first
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

  def update_tracked_fields!(request)
    # Don't update user when he's accessing the API
    if !request.params.key?(:oauth_token) &&
       (!request.headers.key?('HTTP_AUTHORIZATION') || !request.headers['HTTP_AUTHORIZATION'] =~ /OAuth/)
      super(request)
    end
  end

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

  def billing_address_complete?
    [billing_address_1, billing_postal_code, billing_city, billing_country].all?(&:present?)
  end

  def billing_address_missing_fields
    %w[billing_address_1 billing_postal_code billing_city billing_country].reject do |field|
      self.send(field).present?
    end
  end

  def more_info_incomplete?
    [billing_postal_code, billing_country, company_name, company_url, company_job_title, company_employees].any?(&:blank?) ||
    [use_personal, use_company, use_clients].all?(&:blank?) # one of these fields is enough
  end

  def email_support?
    %w[email vip_email].include?(support)
  end

  def billable?
    sites.in_paid_plan.count > 0
  end

  def name_or_email
    name.presence || email
  end

  def billing_address
    Snail.new(
      name:        billing_name.presence || name,
      line_1:      billing_address_1,
      line_2:      billing_address_2,
      postal_code: billing_postal_code,
      city:        billing_city,
      region:      billing_region,
      country:     billing_country.to_s
    ).to_s
  end

  def support
    support_level = sites.active.max { |a, b| a.plan.support_level <=> b.plan.support_level }.try(:plan).try(:support_level) || 0

    Plan::SUPPORT_LEVELS[support_level]
  end

  def plan_title
    plan.try(:title)
  end

  def activated_deals
    deal_activations.active.order{ activated_at.desc }.map(&:deal)
  end

  def latest_activated_deal
    deal_activations.order{ activated_at.desc }.first.try(:deal)
  end

  def latest_activated_deal_still_active
    deal_activations.active.order{ activated_at.desc }.first.try(:deal)
  end

  def support_requests
    @support_requests ||= (zendesk_id? ? ZendeskWrapper.search(query: "requester_id:#{zendesk_id}") : [])
  end

  def create_zendesk_user
    return if zendesk_id?

    zendesk_user = ZendeskWrapper.create_user(self)
    self.update_attribute(:zendesk_id, zendesk_user.id)
  end

  def skip_password(*args)
    action = args.shift
    @skip_password_validation = true
    result = self.send(action, *args)
    @skip_password_validation = false
    result
  end

  def unmemoize_all
    unmemoize_all_activity
  end

private

  # validate
  def validates_current_password
    return if @skip_password_validation
    return if @bypass_postpone # For devise reconfirmation

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

  # before_transition on: :suspend
  def suspend_sites
    sites.active.includes(:invoices).where(invoices: { state: 'failed' }).map(&:suspend)
  end

  # after_transition on: :suspend
  def send_account_suspended_email
    UserMailer.delay.account_suspended(id)
  end

  # before_transition on: :unsuspend
  def unsuspend_sites
    sites.where(state: 'suspended').map(&:unsuspend)
  end

  # after_transition on: :unsuspend
  def send_account_unsuspended_email
    UserMailer.delay.account_unsuspended(id)
  end

  # before_transition on: :archive
  def set_archived_at
    self.archived_at = Time.now.utc
  end
  def archive_sites
    sites.each do |site|
      site.skip_password(:archive)
    end
  end

  # after_transition on: :archive
  def invalidate_tokens
    tokens.update_all(invalidated_at: Time.now.utc)
  end

  # after_transition on: :archive
  def newsletter_unsubscribe
    NewsletterManager.unsubscribe(self)
  end

  # after_transition on: :archive
  def send_account_archived_email
    UserMailer.delay.account_archived(id)
  end

  # before_save
  def set_password
    if @password.present?
      self.encrypted_password = password_digest(@password)
      @password = nil
    end
  end

  # after_create
  def send_welcome_email
    UserMailer.delay.welcome(id)
  end

  # after_create
  def sync_newsletter
    NewsletterManager.sync_from_service(self)
  end

  # after_save
  def newsletter_update
    if newsletter_changed?
      if newsletter?
        NewsletterManager.subscribe(self)
      else
        newsletter_unsubscribe
      end
    end

    if newsletter?
      if (email_changed? && email_was.present?) || (name_changed? && name_was.present? && name?)
        NewsletterManager.update(self)
      end
    end
  end

  # after_update
  def zendesk_update
    if zendesk_id? && (email_changed? || (name_changed? && name?))
      updated_field = email_changed? ? { email: email } : { name: name }
      ZendeskWrapper.delay(priority: 25).update_user(zendesk_id, updated_field)
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
#  archived_at                     :datetime
#  balance                         :integer          default(0)
#  billing_address_1               :string(255)
#  billing_address_2               :string(255)
#  billing_city                    :string(255)
#  billing_country                 :string(255)
#  billing_name                    :string(255)
#  billing_postal_code             :string(255)
#  billing_region                  :string(255)
#  cc_alias                        :string(255)
#  cc_expire_on                    :date
#  cc_last_digits                  :string(255)
#  cc_type                         :string(255)
#  cc_updated_at                   :datetime
#  company_employees               :string(255)
#  company_job_title               :string(255)
#  company_name                    :string(255)
#  company_url                     :string(255)
#  company_videos_served           :string(255)
#  confirmation_comment            :text
#  confirmation_sent_at            :datetime
#  confirmation_token              :string(255)
#  confirmed_at                    :datetime
#  country                         :string(255)
#  created_at                      :datetime         not null
#  current_sign_in_at              :datetime
#  current_sign_in_ip              :string(255)
#  early_access                    :text
#  email                           :string(255)      default(""), not null
#  encrypted_password              :string(128)      default(""), not null
#  enthusiast_id                   :integer
#  failed_attempts                 :integer          default(0)
#  hidden_notice_ids               :text
#  id                              :integer          not null, primary key
#  invitation_accepted_at          :datetime
#  invitation_limit                :integer
#  invitation_sent_at              :datetime
#  invitation_token                :string(60)
#  invited_by_id                   :integer
#  invited_by_type                 :string(255)
#  last_failed_cc_authorize_at     :datetime
#  last_failed_cc_authorize_error  :string(255)
#  last_failed_cc_authorize_status :integer
#  last_invoiced_amount            :integer          default(0)
#  last_sign_in_at                 :datetime
#  last_sign_in_ip                 :string(255)
#  locked_at                       :datetime
#  name                            :string(255)
#  newsletter                      :boolean          default(FALSE)
#  password_salt                   :string(255)      default(""), not null
#  pending_cc_expire_on            :date
#  pending_cc_last_digits          :string(255)
#  pending_cc_type                 :string(255)
#  pending_cc_updated_at           :datetime
#  postal_code                     :string(255)
#  referrer_site_token             :string(255)
#  remember_created_at             :datetime
#  remember_token                  :string(255)
#  reset_password_sent_at          :datetime
#  reset_password_token            :string(255)
#  sign_in_count                   :integer          default(0)
#  state                           :string(255)
#  total_invoiced_amount           :integer          default(0)
#  unconfirmed_email               :string(255)
#  updated_at                      :datetime         not null
#  use_clients                     :boolean
#  use_company                     :boolean
#  use_personal                    :boolean
#  vip                             :boolean          default(FALSE)
#  zendesk_id                      :integer
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

