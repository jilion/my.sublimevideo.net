require 'searchable'

class User < ActiveRecord::Base
  include UserModules::CreditCard
  include Searchable

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :lockable, :async

  def self.cookie_domain
    '.sublimevideo.net'
  end

  # Mail template
  liquid_methods :email, :name

  acts_as_taggable

  attr_accessor :terms_and_conditions, :use, :current_password, :remote_ip
  attr_accessible :email, :remember_me, :password, :current_password, :hidden_notice_ids,
                  :name, :postal_code, :country, :confirmation_comment,
                  :billing_email, :billing_name, :billing_address_1, :billing_address_2,
                  :billing_postal_code, :billing_city, :billing_region, :billing_country,
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
  has_many :billable_items, through: :sites

  # Invoices
  has_many :invoices, through: :sites

  def last_invoice
    @last_invoice ||= invoices.last
  end

  has_many :deal_activations
  has_many :feedbacks

  # API
  has_many :client_applications
  has_many :tokens, class_name: 'OauthToken', order: 'authorized_at DESC', include: [:client_application]

  # ===============
  # = Validations =
  # ===============

  validates :email, presence: true, email_uniqueness: true, format: { with: Devise.email_regexp }
  validates :billing_email, format: { with: Devise.email_regexp }, allow_blank: true

  with_options if: :password_required? do |v|
    v.validates_presence_of :password, on: :create
    v.validates_length_of   :password, within: Devise.password_length, allow_blank: true
  end

  validates :postal_code, :billing_postal_code, length: { maximum: 20 }, allow_blank: true
  validates :company_url, hostname: true, allow_blank: true
  validates :terms_and_conditions, acceptance: true, allow_nil: false, on: :create

  validate :validates_credit_card_attributes # in user/credit_card

  # =============
  # = Callbacks =
  # =============

  before_save :prepare_pending_credit_card, if: ->(user) { user.credit_card(true).valid? } # in user/credit_card

  after_save :register_credit_card_on_file, if: ->(user) { user.cc_register } # in user/credit_card
  after_save :_update_newsletter_subscription
  after_update :_update_newsletter_user_infos

  after_update :zendesk_update

  # =================
  # = State Machine =
  # =================

  state_machine initial: :active do
    event(:suspend)   { transition active: :suspended }
    event(:unsuspend) { transition suspended: :active }
    event(:archive)   { transition all - [:archived] => :archived }

    before_transition on: :archive do |user, transition|
      user.archived_at = Time.now.utc
    end
  end

  # ==========
  # = Scopes =
  # ==========

  # state
  scope :invited,      -> { where { invitation_token != nil } }
  # some beta users don't come from svs but were directly invited from msv!!
  scope :beta,         -> { where { (invitation_token == nil) & (created_at < PublicLaunch.beta_transition_started_on) } }
  scope :active,       -> { where { state == 'active' } }
  scope :inactive,     -> { where { state != 'active' } }
  scope :suspended,    -> { where { state == 'suspended' } }
  scope :archived,     -> { where { state == 'archived' } }
  scope :not_archived, -> { where { state != 'archived' } }

  # billing
  scope :paying,     -> { active.includes(:sites, :billable_items).merge(Site.paying) }
  scope :paying_ids, -> { active.select('DISTINCT(users.id)').joins('INNER JOIN sites ON sites.user_id = users.id INNER JOIN billable_items ON billable_items.site_id = sites.id').merge(BillableItem.subscribed).merge(BillableItem.paid) }
  scope :free,       -> { active.where { id << User.paying_ids } }

  # credit card
  scope :without_cc,           -> { where(cc_type: nil, cc_last_digits: nil) }
  scope :with_cc,              -> { where { (cc_type != nil) & (cc_last_digits != nil) } }
  scope :cc_expire_this_month, -> { where(cc_expire_on: Time.now.utc.end_of_month.to_date) }
  scope :with_balance,         -> { where { balance > 0 } }
  scope :last_credit_card_expiration_notice_sent_before, ->(date) {
      where { last_credit_card_expiration_notice_sent_at < date }
  }

  # attributes queries
  scope :created_on, ->(date) { where { created_at >> date.all_day } }
  scope :newsletter, ->(bool = true) { where(newsletter: bool) }
  scope :vip,        ->(bool = true) { where(vip: bool) }

  scope :sites_tagged_with, ->(word) { joins(:sites).merge(Site.not_archived.tagged_with(word)) }

  scope :with_page_loads_in_the_last_30_days, -> { active.includes(:sites).merge(Site.with_page_loads_in_the_last_30_days) }
  scope :with_stats_realtime_addon_or_invalid_video_tag_data_uid, -> {
    site_with_realtime_addon_tokens = Site.with_addon_plan('stats-realtime').select(:token).uniq.map(&:token)
    site_with_invalide_video_tag_data_uid = VideoTag.site_tokens(with_invalid_uid: true)
    joins(:sites).where(sites: { token: (site_with_realtime_addon_tokens + site_with_invalide_video_tag_data_uid).uniq })
  }

  # sort
  scope :by_name_or_email,         ->(way = 'asc') { order("users.name #{way}, users.email #{way}") }
  scope :by_last_invoiced_amount,  ->(way = 'desc') { order("users.last_invoiced_amount #{way}") }
  scope :by_total_invoiced_amount, ->(way = 'desc') { order("users.total_invoiced_amount #{way}") }
  scope :by_beta,                  ->(way = 'desc') { order("users.invitation_token #{way}") }
  scope :by_date,                  ->(way = 'desc') { order("users.created_at #{way}") }

  def self.additional_or_conditions
    lower_and_match_fields(%w[email name])
  end

  # =================
  # = Class Methods =
  # =================

  # Devise overriding
  # avoid the "not active yet" flash message to be displayed for archived users!
  def self.find_for_authentication(tainted_conditions)
    super(tainted_conditions.merge(state: %w[active suspended]))
  end

  def self.find_first_by_auth_conditions(tainted_conditions, opts={})
    super(tainted_conditions, opts.merge(state: %w[active suspended]))
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
    invitation_token.nil? && created_at < PublicLaunch.beta_transition_started_on
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
    [company_name, company_url, company_job_title, company_employees].any?(&:blank?) ||
    [use_personal, use_company, use_clients].all?(&:blank?) # one of these fields is enough
  end

  def billable?
    sites.not_archived.paying.count > 0
  end

  def trial_or_billable?
    billable? || sites.not_archived.any? { |site| site.total_billable_items_price > 0 }
  end

  def sponsored?
    sites.not_archived.includes(:billable_items).where { billable_items.state == 'sponsored' }.present?
  end

  def name_or_email
    name.presence || email
  end

  def billing_name_or_billing_email
    billing_name.presence || billing_email
  end

  def billing_address(fallback_to_name = true)
    Snail.new(
      name:        billing_name.presence || (fallback_to_name ? name : nil),
      line_1:      billing_address_1,
      line_2:      billing_address_2,
      postal_code: billing_postal_code,
      city:        billing_city,
      region:      billing_region,
      country:     billing_country.to_s
    ).to_s
  end

  def activated_deals
    deal_activations.active.order { activated_at.desc }.map(&:deal)
  end

  def latest_activated_deal
    deal_activations.order { activated_at.desc }.first.try(:deal)
  end

  def latest_activated_deal_still_active
    deal_activations.active.order { activated_at.desc }.first.try(:deal)
  end

  def support_requests
    @support_requests ||= (zendesk_id? ? ZendeskWrapper.search(query: "requester_id:#{zendesk_id}") : [])
  end

  private

  # after_save
  def _update_newsletter_subscription
    return unless newsletter_changed?

    if newsletter?
      NewsletterSubscriptionManager.delay.subscribe(self.id)
    else
      NewsletterSubscriptionManager.delay.unsubscribe(self.id)
    end
  end

  # after_update
  def _update_newsletter_user_infos
    return unless newsletter?

    if email_changed? || name_changed?
      NewsletterSubscriptionManager.delay.update(self.id, email_was || email)
    end
  end

  # after_update
  def zendesk_update
    if zendesk_id? && (email_changed? || (name_changed? && name?))
      updated_field = email_changed? ? { email: email } : { name: name }
      ZendeskWrapper.delay(queue: 'low').update_user(zendesk_id, updated_field)
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
#  archived_at                                :datetime
#  balance                                    :integer          default(0)
#  billing_address_1                          :string(255)
#  billing_address_2                          :string(255)
#  billing_city                               :string(255)
#  billing_country                            :string(255)
#  billing_email                              :string(255)
#  billing_name                               :string(255)
#  billing_postal_code                        :string(255)
#  billing_region                             :string(255)
#  cc_alias                                   :string(255)
#  cc_expire_on                               :date
#  cc_last_digits                             :string(255)
#  cc_type                                    :string(255)
#  cc_updated_at                              :datetime
#  company_employees                          :string(255)
#  company_job_title                          :string(255)
#  company_name                               :string(255)
#  company_url                                :string(255)
#  company_videos_served                      :string(255)
#  confirmation_comment                       :text
#  confirmation_sent_at                       :datetime
#  confirmation_token                         :string(255)
#  confirmed_at                               :datetime
#  country                                    :string(255)
#  created_at                                 :datetime         not null
#  current_sign_in_at                         :datetime
#  current_sign_in_ip                         :string(255)
#  early_access                               :text
#  email                                      :string(255)      default(""), not null
#  encrypted_password                         :string(128)      default(""), not null
#  enthusiast_id                              :integer
#  failed_attempts                            :integer          default(0)
#  hidden_notice_ids                          :text
#  id                                         :integer          not null, primary key
#  invitation_accepted_at                     :datetime
#  invitation_limit                           :integer
#  invitation_sent_at                         :datetime
#  invitation_token                           :string(60)
#  invited_by_id                              :integer
#  invited_by_type                            :string(255)
#  last_credit_card_expiration_notice_sent_at :datetime
#  last_failed_cc_authorize_at                :datetime
#  last_failed_cc_authorize_error             :string(255)
#  last_failed_cc_authorize_status            :integer
#  last_invoiced_amount                       :integer          default(0)
#  last_sign_in_at                            :datetime
#  last_sign_in_ip                            :string(255)
#  locked_at                                  :datetime
#  name                                       :string(255)
#  newsletter                                 :boolean          default(FALSE)
#  password_salt                              :string(255)      default(""), not null
#  pending_cc_expire_on                       :date
#  pending_cc_last_digits                     :string(255)
#  pending_cc_type                            :string(255)
#  pending_cc_updated_at                      :datetime
#  postal_code                                :string(255)
#  referrer_site_token                        :string(255)
#  remember_created_at                        :datetime
#  remember_token                             :string(255)
#  reset_password_sent_at                     :datetime
#  reset_password_token                       :string(255)
#  sign_in_count                              :integer          default(0)
#  state                                      :string(255)
#  total_invoiced_amount                      :integer          default(0)
#  unconfirmed_email                          :string(255)
#  updated_at                                 :datetime         not null
#  use_clients                                :boolean
#  use_company                                :boolean
#  use_personal                               :boolean
#  vip                                        :boolean          default(FALSE)
#  zendesk_id                                 :integer
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

