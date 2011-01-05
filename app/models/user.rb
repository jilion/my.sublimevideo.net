class User < ActiveRecord::Base
  include CreditCard

  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :lockable, :invitable

  # Pagination
  cattr_accessor :per_page
  self.per_page = 50

  # Mail template
  liquid_methods :email, :first_name, :last_name, :full_name

  attr_accessor :terms_and_conditions, :use
  attr_accessible :first_name, :last_name, :email, :remember_me, :password, :postal_code, :country,
                  :use_personal, :use_company, :use_clients,
                  :company_name, :company_url, :company_job_title, :company_employees, :company_videos_served,
                  :newsletter, :terms_and_conditions
  # Credit card
  attr_accessible :cc_update, :cc_type, :cc_full_name, :cc_number, :cc_expire_on, :cc_verification_value

  # ================
  # = Associations =
  # ================

  belongs_to :suspending_delayed_job, :class_name => "::Delayed::Job"
  has_many :sites
  has_many :invoices

  # ==========
  # = Scopes =
  # ==========

  def self.billable(started_at, ended_at)
    includes(:sites).
    without_state(:archived).
    where(:sites => [{ :activated_at.lte => ended_at }, { :archived_at => nil } | { :archived_at.gte => started_at }])
  end

  # credit_card scopes
  scope :without_cc, where(:cc_type => nil, :cc_last_digits => nil)
  scope :with_cc,    where(:cc_type.ne => nil, :cc_last_digits.ne => nil)

  # admin
  scope :enthusiast,        where(:enthusiast_id.ne => nil)
  scope :invited,           where(:invitation_token.ne => nil)
  scope :beta,              where(:invitation_token => nil)
  scope :use_personal,      where(:use_personal => true)
  scope :use_company,       where(:use_company => true)
  scope :use_clients,       where(:use_clients => true)
  scope :will_be_suspended, where(:suspending_delayed_job_id.ne => nil)

  # sort
  scope :by_name_or_email, lambda { |way = 'asc'| order(:first_name.send(way), :email.send(way)) }
  scope :by_beta,          lambda { |way = 'desc'| order(:invitation_token.send(way)) }
  scope :by_date,          lambda { |way = 'desc'| order(:created_at.send(way)) }

  # search
  def self.search(q)
    joins(:sites).
    where(:lower.func(:email).matches % :lower.func("%#{q}%") \
        | :lower.func(:first_name).matches % :lower.func("%#{q}%") \
        | :lower.func(:last_name).matches % :lower.func("%#{q}%") \
        | :lower.func(:hostname).matches % :lower.func("%#{q}%") \
        | :lower.func(:dev_hostnames).matches % :lower.func("%#{q}%"))
  end

  # ===============
  # = Validations =
  # ===============

  validates_presence_of     :email
  validates                 :email, :email_uniqueness => true
  validates_format_of       :email, :with => Devise.email_regexp, :allow_blank => true

  with_options :if => :password_required? do |v|
    v.validates_presence_of     :password
    v.validates_confirmation_of :password
    v.validates_length_of       :password, :within => Devise.password_length, :allow_blank => true
  end

  validates :first_name,  :presence => true
  validates :last_name,   :presence => true
  validates :postal_code, :presence => true
  validates :country,     :presence => true
  validates :company_url, :hostname => true, :allow_blank => true
  validates :terms_and_conditions, :acceptance => { :accept => "1" }, :on => :create

  validate :validates_credit_card_attributes # in user/credit_card
  validate :validates_use_presence, :on => :create
  validate :validates_company_fields, :on => :create

  # =============
  # = Callbacks =
  # =============

  before_save   :store_credit_card, :keep_some_credit_card_info # in user/credit_card
  after_update  :update_email_on_zendesk, :charge_failed_invoices
<<<<<<< HEAD
  after_save    :newsletter_subscription
  
=======

>>>>>>> d94ba734b0f40173051efb447fc54da75cae7176
  # =================
  # = State Machine =
  # =================

  state_machine :initial => :active do
    event(:suspend)        { transition :active => :suspended }
    event(:cancel_suspend) { transition :active => :active }
    event(:unsuspend)      { transition :suspended => :active }
    event(:archive)        { transition :active => :archived }

    before_transition :on => :suspend, :do => [:set_failed_invoices_count_on_suspend, :suspend_sites]
    after_transition  :on => :suspend, :do => :send_account_suspended_email

    before_transition :on => :cancel_suspend, :do => :delete_suspending_delayed_job

    before_transition :on => :unsuspend, :do => [:set_failed_invoices_count_on_suspend, :unsuspend_sites]
    after_transition  :on => :unsuspend, :do => :send_account_unsuspended_email

    before_transition :on => :archive, :do => [:set_archived_at, :archive_sites, :delay_complete_current_invoice]
    after_transition  :on => :archive, :do => :send_account_archived_email
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
  # allow suspended user to login (devise)
  def active?
    %w[active suspended].include?(state) && invitation_token.nil?
  end

  def get_discount?
    remaining_discounted_months? && remaining_discounted_months > 0
  end

  def full_name
    first_name.to_s + ' ' + last_name.to_s
  end

  def email=(email)
    write_attribute(:email, email.try(:downcase))
  end

  def delay_suspend(run_at = Billing.days_before_suspend_user.days.from_now)
    transaction do
      begin
        delayed_job = User.delay(:run_at => run_at).suspend(self.id)
        self.update_attribute(:suspending_delayed_job_id, delayed_job.id)
      rescue => ex
        Notify.send("User#suspend for user ##{self.id} has failed: #{ex.message}", :exception => ex)
      end
    end
  end

  def will_be_suspended?
    suspending_delayed_job
  end

private

  # validate
  def validates_use_presence
    if !use_personal && !use_company && !use_clients
      self.errors.add(:use, :at_least_one_option)
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

  # before_transition :on => :suspend, before_transition :on => :unsuspend
  def set_failed_invoices_count_on_suspend
    self.failed_invoices_count_on_suspend = invoices.failed.count
  end

  # before_transition :on => :suspend
  def suspend_sites
    sites.map(&:suspend)
  end

  # after_transition :on => :suspend
  def send_account_suspended_email
    UserMailer.account_suspended(self).deliver!
  end

  # before_transition :on => :cancel_suspend
  def delete_suspending_delayed_job
    Delayed::Job.find(suspending_delayed_job_id).delete
    self.suspending_delayed_job_id = nil
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
    sites.map(&:archive)
  end
  def delay_complete_current_invoice
    Invoice.usage_statement(self).delay.complete
  end
  
  # after_transition :on => :archive
  def send_account_archived_email
    UserMailer.account_archived(self).deliver!
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
      invoices.failed.each { |invoice| invoice.retry }
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
#  id                               :integer         not null, primary key
#  state                            :string(255)
#  email                            :string(255)     default(""), not null
#  encrypted_password               :string(128)     default(""), not null
#  password_salt                    :string(255)     default(""), not null
#  confirmation_token               :string(255)
#  confirmed_at                     :datetime
#  confirmation_sent_at             :datetime
#  reset_password_token             :string(255)
#  remember_token                   :string(255)
#  remember_created_at              :datetime
#  sign_in_count                    :integer         default(0)
#  current_sign_in_at               :datetime
#  last_sign_in_at                  :datetime
#  current_sign_in_ip               :string(255)
#  last_sign_in_ip                  :string(255)
#  failed_attempts                  :integer         default(0)
#  locked_at                        :datetime
#  cc_type                          :string(255)
#  cc_last_digits                   :integer
#  cc_expire_on                     :date
#  cc_updated_at                    :datetime
#  created_at                       :datetime
#  updated_at                       :datetime
#  invitation_token                 :string(20)
#  invitation_sent_at               :datetime
#  zendesk_id                       :integer
#  enthusiast_id                    :integer
#  first_name                       :string(255)
#  last_name                        :string(255)
#  postal_code                      :string(255)
#  country                          :string(255)
#  use_personal                     :boolean
#  use_company                      :boolean
#  use_clients                      :boolean
#  company_name                     :string(255)
#  company_url                      :string(255)
#  company_job_title                :string(255)
#  company_employees                :string(255)
#  company_videos_served            :string(255)
#  suspending_delayed_job_id        :integer
#  failed_invoices_count_on_suspend :integer         default(0)
#  archived_at                      :datetime
#  remaining_discounted_months      :integer
#  newsletter                       :boolean
#
# Indexes
#
#  index_users_on_confirmation_token     (confirmation_token) UNIQUE
#  index_users_on_email_and_archived_at  (email,archived_at) UNIQUE
#  index_users_on_reset_password_token   (reset_password_token) UNIQUE
#
