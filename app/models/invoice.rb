class Invoice < ActiveRecord::Base

  uniquify :reference, :chars => Array('A'..'Z') + Array('1'..'9')

  # ================
  # = Associations =
  # ================

  belongs_to :user
  belongs_to :charging_delayed_job, :class_name => "::Delayed::Job"
  has_many :invoice_items

  # ==========
  # = Scopes =
  # ==========

  scope :failed, where(:state => 'failed')

  # ===============
  # = Validations =
  # ===============

  validates :user,                 :presence => true
  validates :started_at,           :presence => true
  validates :ended_at,             :presence => true
  validates :invoice_items_amount, :presence => true, :numericality => true
  validates :vat_rate,             :presence => true, :numericality => true
  validates :vat_amount,           :presence => true, :numericality => true
  validates :amount,               :presence => true, :numericality => true

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :open do
    event(:complete) do
      transition :open => :paid, :if => lambda { |invoice| invoice.amount == 0 }
      transition :open => :failed, :if => lambda { |invoice| invoice.user.cc_expired? }
      transition :open => :unpaid
    end
    event(:retry) { transition :failed => :failed }
    event(:fail) do
      transition :unpaid => :unpaid, :if => lambda { |invoice| invoice.attempts < Billing.max_charging_attempts }
      transition [:unpaid, :failed] => :failed
    end
    event(:succeed) { transition [:unpaid, :failed] => :paid }

    before_transition :on => :complete, :do => :set_completed_at
    after_transition  :on => :complete, :do => :decrement_user_remaining_discounted_months

    before_transition :on => :retry, :do => :delay_charge

    before_transition :open => :unpaid, :unpaid => [:unpaid, :failed], :do => :delay_charge, :unless => lambda { |invoice| invoice.user.suspended? }
    after_transition  :open => :unpaid, :do => :send_invoice_completed_email, :unless => lambda { |invoice| invoice.user.archived? }

    before_transition any => :failed, :do => [:set_failed_at, :clear_charging_delayed_job_id]
    before_transition :unpaid => :failed, :do => :delay_suspend_user
    after_transition  :unpaid => :failed, :do => :send_charging_failed_email

    before_transition any => :paid, :do => [:set_paid_at, :clear_charging_delayed_job_id]
    after_transition  any => :paid do |invoice, transition|
      if invoice.user.suspended? && invoice.user.invoices.failed.empty?
        User.delay.unsuspend(invoice.user_id)
      elsif invoice.user.will_be_suspended?
        invoice.user.cancel_suspend
      end
    end
  end

  # =================
  # = Class Methods =
  # =================

  def self.build(attributes = {})
    new(attributes).build
  end

  def self.usage_statement(user)
    build(
      :user       => user,
      :started_at => Time.now.utc.beginning_of_month,
      :ended_at   => Time.now.utc
    )
  end

  def self.delay_complete_invoices_for_billable_users(started_at, ended_at)
    unless Delayed::Job.already_delayed?('%Invoice%complete_invoices_for_billable_users%')
      delay(:priority => 1, :run_at => ended_at + Billing.days_before_creating_invoice.days).complete_invoices_for_billable_users(started_at, ended_at)
    end
  end

  def self.complete_invoices_for_billable_users(started_at, ended_at) # utc dates!
    User.billable(started_at, ended_at).each do |user|
      invoice = build(:user => user, :started_at => started_at, :ended_at => ended_at)
      invoice.complete
    end
    delay_complete_invoices_for_billable_users(*TimeUtil.next_full_month(ended_at))
  end

  def self.charge(invoice_id)
    invoice = find(invoice_id)
    return if invoice.paid?

    @payment = begin
      Ogone.purchase(invoice.amount, invoice.user.credit_card_alias, :order_id => invoice.reference, :currency => 'USD')
    rescue => ex
      Notify.send("Charging failed: #{ex.message}", :exception => ex)
      invoice.last_error = ex.message
      nil
    end
    invoice.increment_attempts

    if @payment && (@payment.success? || @payment.params["NCERROR"] == "50001113") # 50001113: orderID already processed with success
      invoice.succeed
    else
      invoice.last_error = @payment.message if @payment
      invoice.fail
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  def build
    build_invoice_items
    set_invoice_items_amount
    set_discount_rate_and_amount
    set_vat_rate_and_amount
    set_amount
    self
  end

  def minutes_in_months
    ((ended_at.end_of_month - started_at.beginning_of_month).to_f / 60).ceil
  end

  def to_param
    reference
  end

  def total_invoice_items_amount
    @total_invoice_items_amount ||= invoice_items.inject(0) { |sum, invoice_item| sum + invoice_item.amount }
  end

  def will_be_charged?
    charging_delayed_job
  end

  # before_transition :on => [:fail, :succeed]
  def increment_attempts
    self.attempts += 1
  end

private

  def build_invoice_items
    user.sites.includes(:versions).billable(started_at, ended_at).each do |site|
      # Allow to have the good billable plan
      past_site = site.version_at(ended_at)
      # Plan
      invoice_items << (plan_invoice_item = InvoiceItem::Plan.build(:site => past_site, :invoice => self))
      # Overages
      invoice_items << InvoiceItem::Overage.build(:site => past_site, :invoice => self)
      # Addons
      past_site.lifetimes.where(:item_type => "Addon").alive_between(plan_invoice_item.started_at, plan_invoice_item.ended_at).each do |lifetime|
        invoice_items << InvoiceItem::Addon.build(:site => past_site, :lifetime => lifetime, :invoice => self)
      end
    end
  end

  def set_invoice_items_amount
    self.invoice_items_amount = if !total_invoice_items_amount.zero? && total_invoice_items_amount < Billing.minimum_billable_amount
      Billing.minimum_billable_amount
    else
      total_invoice_items_amount
    end
  end

  def set_discount_rate_and_amount
    self.discount_rate   = self.user.get_discount? ? Billing.beta_discount_rate : 0.0
    self.discount_amount = (invoice_items_amount * discount_rate).round
  end

  def set_vat_rate_and_amount
    self.vat_rate   = Vat.for_country(user.country)
    self.vat_amount = ((invoice_items_amount - discount_amount) * vat_rate).round
  end

  def set_amount
    self.amount = invoice_items_amount - discount_amount + vat_amount
  end

  # before_transition [:open, :unpaid] => [:unpaid, :failed], before_transition :on => :retry
  def delay_charge
    delayed_job = Invoice.delay(:run_at => charging_delay).charge(self.id)
    self.charging_delayed_job_id = delayed_job.id
  end

  # after_transition :open => :unpaid
  def send_invoice_completed_email
    InvoiceMailer.invoice_completed(self).deliver!
  end

  # before_transition :on => :complete
  def set_completed_at
    self.completed_at = Time.now.utc
  end

  # after_transition :on => :complete
  def decrement_user_remaining_discounted_months
    self.user.decrement(:remaining_discounted_months) if user.get_discount?
  end

  # before_transition any => :failed, before_transition any => :paid
  def clear_charging_delayed_job_id
    self.charging_delayed_job_id = nil
  end

  # before_transition any => :failed
  def set_failed_at
    self.failed_at = Time.now.utc
  end

  # before_transition :unpaid => :failed
  def delay_suspend_user
    self.user.delay_suspend
  end

  # after_transition  :unpaid => :failed
  def send_charging_failed_email
    InvoiceMailer.charging_failed(self).deliver!
  end

  # before_transition any => :paid
  def set_paid_at
    self.paid_at = Time.now.utc
  end

  def charging_delay
    if user.suspended? || user.archived?
      0.seconds
    elsif open?
      Billing.days_before_charging.days
    elsif attempts >= Billing.max_charging_attempts
      Billing.hours_between_retries_before_user_suspend.hours
    else
      (2**attempts).hours
    end.from_now
  end

end


# == Schema Information
#
# Table name: invoices
#
#  id                      :integer         not null, primary key
#  user_id                 :integer
#  reference               :string(255)
#  state                   :string(255)
#  amount                  :integer
#  started_at              :datetime
#  ended_at                :datetime
#  paid_at                 :datetime
#  attempts                :integer         default(0)
#  last_error              :string(255)
#  failed_at               :datetime
#  created_at              :datetime
#  updated_at              :datetime
#  completed_at            :datetime
#  charging_delayed_job_id :integer
#  invoice_items_amount    :integer
#  vat_rate                :float
#  vat_amount              :integer
#  discount_rate           :float           default(0.0)
#  discount_amount         :float           default(0.0)
#
# Indexes
#
#  index_invoices_on_user_id                 (user_id)
#  index_invoices_on_user_id_and_ended_at    (user_id,ended_at) UNIQUE
#  index_invoices_on_user_id_and_started_at  (user_id,started_at) UNIQUE
#

