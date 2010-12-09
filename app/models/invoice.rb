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
  validates :amount,               :presence => true, :numericality => true
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :open do
    event(:complete) do
      transition :open => :paid, :if => lambda { |invoice| invoice.amount == 0 }
      transition :open => :unpaid
    end
    event(:retry)   { transition :failed => :failed }
    event(:fail) do
      transition :unpaid => :unpaid, :if => lambda { |invoice| invoice.attempts < Billing.max_charging_attempts }
      transition [:unpaid, :failed] => :failed
    end
    event(:succeed) { transition [:unpaid, :failed] => :paid }
    
    before_transition :on => :complete, :do => :set_completed_at
    
    before_transition :on => [:fail, :succeed], :do => :increment_attempts
    
    before_transition :on => :retry, :do => :delay_charge_and_set_charging_delayed_job_id
    
    before_transition [:open, :unpaid] => [:unpaid, :failed], :do => :delay_charge_and_set_charging_delayed_job_id, :unless => lambda { |invoice| invoice.user.suspended? }
    after_transition  :open => :unpaid, :do => :send_invoice_completed_email
    
    before_transition any => :failed, :do => [:set_failed_at, :clear_charging_delayed_job_id]
    before_transition :unpaid => :failed, :do => :delay_suspend_user
    after_transition  :unpaid => :failed, :do => :send_charging_failed_email
    
    before_transition any => :paid, :do => [:set_paid_at, :clear_charging_delayed_job_id]
    after_transition  any => :paid do |invoice, transition|
      if invoice.user.suspended? && invoice.user.invoices.failed.empty?
        User.delay.unsuspend(invoice.user_id)
      elsif invoice.user.suspending_delayed_job_id?
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
    delay_complete_invoices_for_billable_users(ended_at.next_month.beginning_of_month, ended_at.next_month.end_of_month)
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
  
public
  
  def build
    build_invoice_items
    set_invoice_items_amount
    set_transaction_fees
    set_vat
    set_amount
    self
  end
  
  def minutes_in_months
    ((ended_at.end_of_month - started_at.beginning_of_month).to_f / 60).ceil
  end
  
  def to_param
    reference
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
    self.invoice_items_amount = invoice_items.inject(0) { |sum, invoice_item| sum + invoice_item.amount }
  end
  
  def set_transaction_fees
    self.transaction_fees = 0
  end
  
  def set_vat
    self.vat_rate   = Vat.for_country(user.country)
    self.vat_amount = ((invoice_items_amount + transaction_fees) * vat_rate).round
  end
  
  def set_amount
    self.amount = invoice_items_amount + transaction_fees + vat_amount
  end
  
  # before_transition any => [:unpaid, :failed]
  def delay_charge_and_set_charging_delayed_job_id
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
  
  # before_transition :on => [:fail, :succeed]
  def increment_attempts
    self.attempts += 1
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
    self.user.delay_suspend_and_set_suspending_delayed_job_id
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
    if open?
      Billing.days_before_charging.days
    elsif user.suspended?
      0.seconds
    elsif attempts > Billing.max_charging_attempts
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
#  transaction_fees        :integer
#
# Indexes
#
#  index_invoices_on_user_id                 (user_id)
#  index_invoices_on_user_id_and_ended_at    (user_id,ended_at) UNIQUE
#  index_invoices_on_user_id_and_started_at  (user_id,started_at) UNIQUE
#

