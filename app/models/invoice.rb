require_dependency 'vat'

StateMachine::Machine.ignore_method_conflicts = true

class Invoice < ActiveRecord::Base
  include InvoiceModules::Scope

  uniquify :reference, chars: Array('a'..'z') - ['o'] + Array('1'..'9')

  attr_accessible :site, :renew

  # ================
  # = Associations =
  # ================

  belongs_to :site
  has_one :user, through: :site

  # Invoice items
  has_many :invoice_items
  has_many :plan_invoice_items, conditions: { type: "InvoiceItem::Plan" }

  has_and_belongs_to_many :transactions

  delegate :user, to: :site

  # =============
  # = Callbacks =
  # =============

  before_create ->(invoice) do
    invoice.customer_full_name       = invoice.user.billing_name
    invoice.customer_email           = invoice.user.email
    invoice.customer_country         = invoice.user.billing_country
    invoice.customer_company_name    = invoice.user.company_name
    invoice.customer_billing_address = invoice.user.billing_address
    invoice.site_hostname            = invoice.site.hostname
  end

  after_create ->(invoice) do
    invoice.user.decrement!(:balance, invoice.balance_deduction_amount) unless invoice.balance_deduction_amount.zero?
  end
  after_create ->(invoice) { invoice.succeed! if invoice.amount.zero? }

  # ===============
  # = Validations =
  # ===============

  validates :site,                     presence: true
  validates :invoice_items_amount,     presence: true, numericality: true
  validates :vat_rate,                 presence: true, numericality: true
  validates :vat_amount,               presence: true, numericality: true
  validates :balance_deduction_amount, presence: true, numericality: true
  validates :amount,                   presence: true, numericality: true

  # =================
  # = State Machine =
  # =================

  state_machine initial: :open do
    event(:succeed) { transition [:open, :failed, :waiting] => :paid }
    event(:fail)    { transition [:open, :failed, :waiting] => :failed }
    event(:wait)    { transition [:open, :failed, :waiting] => :waiting }
    event(:cancel)  { transition [:open, :failed] => :canceled }

    before_transition on: :succeed do |invoice, transition|
      invoice.paid_at        = Time.now.utc
      invoice.last_failed_at = nil
    end
    after_transition on: :succeed do |invoice, transition|
      invoice.user.last_invoiced_amount   = invoice.amount
      invoice.user.total_invoiced_amount += invoice.amount
      invoice.user.save
    end
    after_transition on: :succeed do |invoice, transition|
      invoice.user.unsuspend if invoice.user.suspended? && invoice.user.invoices.not_paid.empty?
    end

    after_transition  on: :cancel do |invoice, transition|
      invoice.user.increment!(:balance, invoice.balance_deduction_amount) unless invoice.balance_deduction_amount.zero?
    end

    before_transition on: :fail do |invoice, transition|
      invoice.last_failed_at = Time.now.utc
    end
  end

  def self.total_revenue
    self.paid.sum(:amount)
  end

  def to_param
    reference
  end

  def last_transaction
    transactions.order{ created_at.asc }.last
  end

  def refunded?
    site.refunded_at?
  end

  def first_paid_item
    invoice_items.find { |pii| pii.amount > 0 }.try(:item)
  end

end

# == Schema Information
#
# Table name: invoices
#
#  amount                   :integer
#  balance_deduction_amount :integer          default(0)
#  created_at               :datetime         not null
#  customer_billing_address :text
#  customer_company_name    :string(255)
#  customer_country         :string(255)
#  customer_email           :string(255)
#  customer_full_name       :string(255)
#  id                       :integer          not null, primary key
#  invoice_items_amount     :integer
#  invoice_items_count      :integer          default(0)
#  last_failed_at           :datetime
#  paid_at                  :datetime
#  reference                :string(255)
#  renew                    :boolean          default(FALSE)
#  site_hostname            :string(255)
#  site_id                  :integer
#  state                    :string(255)
#  transactions_count       :integer          default(0)
#  updated_at               :datetime         not null
#  vat_amount               :integer
#  vat_rate                 :float
#
# Indexes
#
#  index_invoices_on_reference  (reference) UNIQUE
#  index_invoices_on_site_id    (site_id)
#

