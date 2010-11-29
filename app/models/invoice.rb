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
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user,       :presence => true
  validates :started_at, :presence => true
  validates :ended_at,   :presence => true
  validates :amount,     :presence => true, :numericality => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :open do
    state :unpaid
    
    event(:complete) do
      transition :open => :paid, :if => :amount_is_zero?
      transition :open => :unpaid
    end
    event(:charge) { transition [:unpaid, :failed] => [:paid, :failed] }
    
    before_transition :on => :complete, :do => :set_completed_at
    after_transition :open => :unpaid, :do => [:delay_charge, :send_invoice_completed_email]
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.build(attributes = {})
    new(attributes).build
  end
  
  def self.usage_statement(user)
    build(
      :user => user,
      :started_at => Time.now.utc.beginning_of_month,
      :ended_at => Time.now.utc
    )
  end
  
  def self.complete_invoices_for_billable_users(started_at, ended_at) # utc dates!
    User.billable(started_at, ended_at).each do |user|
      invoice = build(:user => user, :started_at => started_at, :ended_at => ended_at)
      invoice.complete
    end
  end
  
  def self.charge(invoice_id)
    invoice = find(invoice_id)
    # TODO Add VAT & transaction fees !!
    final_amount = invoice.amount # + var + transaction_fees
    
    transaction do
      begin
        payment = Ogone.purchase(final_amount, invoice.user.credit_card_alias, :currency => 'USD')
        
        if payment.success?
          invoice.update_attributes(:charging_delayed_job_id => nil, :state => 'paid', :paid_at => Time.now.utc)
        elsif invoice.attempts < Billing.max_charging_attempts
          invoice.update_attributes(:last_error => payment.message, :state => 'unpaid')
          invoice.delay_charge # will retry after 2, 4, 8 and 16 hours
        else # failed !!
          invoice.update_attributes(:charging_delayed_job_id => nil, :last_error => payment.message, :state => 'failed')
          User.delay_suspend(invoice.user_id)
          InvoiceMailer.payment_failed(invoice).deliver!
        end
      rescue => ex
        Notify.send("Charging failed: #{ex.message}", :exception => ex)
      end
    end
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
public
  
  def build
    build_invoice_items
    set_amount
    set_transaction_fees
    set_vat
    self
  end
  
  def minutes_in_months
    ((ended_at.end_of_month - started_at.beginning_of_month).to_f / 60).ceil
  end
  
  def to_param
    reference
  end
  
  # after_transition :open => :unpaid
  def delay_charge
    transaction do
      begin
        delayed_job = self.class.delay(:run_at => charging_delay).charge(self.id)
        self.update_attributes(:attempts => attempts + 1, :charging_delayed_job_id => delayed_job.id)
      rescue => ex
        Notify.send("Delay cherging failed: #{ex.message}", :exception => ex)
      end
    end
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
  
  def set_amount
    self.amount = invoice_items.inject(0) { |sum, invoice_item| sum + invoice_item.amount }
  end
  
  def set_transaction_fees
  end
  
  def set_vat
  end
  
  # before_transition :on => :complete
  def set_completed_at
    self.completed_at = Time.now.utc
  end
  
  # after_transition :open => :unpaid
  def send_invoice_completed_email
    InvoiceMailer.invoice_completed(self).deliver!
  end
  
  def amount_is_zero?
    amount <= 0
  end
  
  def charging_delay
    (attempts == 0 ? Billing.days_before_charging.days : (2**attempts).hours).from_now
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
#
# Indexes
#
#  index_invoices_on_user_id                 (user_id)
#  index_invoices_on_user_id_and_ended_at    (user_id,ended_at) UNIQUE
#  index_invoices_on_user_id_and_started_at  (user_id,started_at) UNIQUE
#

