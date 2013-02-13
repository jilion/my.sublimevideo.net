StateMachine::Machine.ignore_method_conflicts = true

class Invoice < ActiveRecord::Base
  uniquify :reference, chars: Array('a'..'z') - ['o'] + Array('1'..'9')

  attr_accessible :site, :renew

  # ================
  # = Associations =
  # ================

  belongs_to :site
  has_one :user, through: :site

  # Invoice items
  has_many :invoice_items
  has_many :plan_invoice_items,  class_name: 'InvoiceItem', conditions: { type: 'InvoiceItem::Plan' }

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
    invoice.succeed! if invoice.amount.zero?
  end

  # ===============
  # = Validations =
  # ===============

  validates :site, presence: true
  validates :invoice_items_amount, :vat_rate, :vat_amount, :balance_deduction_amount, :amount, presence: true, numericality: true

  # =================
  # = State Machine =
  # =================

  state_machine initial: :open do
    event(:succeed) { transition [:open, :failed, :waiting] => :paid }
    event(:fail)    { transition [:open, :failed, :waiting] => :failed }
    event(:wait)    { transition [:open, :failed, :waiting] => :waiting }
    event(:cancel)  { transition [:open, :failed, :paid] => :canceled }

    before_transition on: :succeed do |invoice, transition|
      invoice.paid_at        = Time.now.utc
      invoice.last_failed_at = nil
    end
    after_transition on: :succeed do |invoice, transition|
      invoice.user.last_invoiced_amount   = invoice.amount
      invoice.user.total_invoiced_amount += invoice.amount
      invoice.user.save
      UserManager.new(invoice.user).unsuspend if invoice.user.suspended? && invoice.user.invoices.not_paid.empty?
    end

    after_transition on: :cancel do |invoice, transition|
      invoice.user.increment!(:balance, invoice.balance_deduction_amount) unless invoice.balance_deduction_amount.zero?
    end

    before_transition on: :fail do |invoice, transition|
      invoice.last_failed_at = Time.now.utc
    end
  end

  # ==========
  # = Scopes =
  # ==========

  scope :paid_between, lambda { |started_at, ended_at| between(paid_at: started_at..ended_at) }

  scope :open,           where(state: 'open')
  scope :paid,           where(state: 'paid').includes(:site).where{ sites.refunded_at == nil }
  scope :refunded,       where(state: 'paid').includes(:site).where{ sites.refunded_at != nil }
  scope :failed,         where(state: 'failed')
  scope :waiting,        where(state: 'waiting')
  scope :canceled,       where(state: 'canceled')
  scope :open_or_failed, where(state: %w[open failed])
  scope :not_canceled,   where{ state != 'canceled' }
  scope :not_paid,       where(state: %w[open waiting failed])
  scope :renew,          lambda { |bool=true| where(renew: bool) }
  scope :site_id,        lambda { |site_id| where(site_id: site_id) }
  scope :user_id,        lambda { |user_id| joins(:user).where{ user.id == user_id } }

  scope :for_month, ->(date) {
    not_canceled.includes(:invoice_items)
    .where { invoice_items.started_at >= date.beginning_of_month }.where { invoice_items.started_at <= date.end_of_month }
    .where { invoice_items.ended_at >= date.beginning_of_month }.where { invoice_items.ended_at <= date.end_of_month }
  }

  # sort
  scope :by_id,                  lambda { |way='desc'| order("invoices.id #{way}") }
  scope :by_date,                lambda { |way='desc'| order("invoices.paid_at #{way}, invoices.last_failed_at #{way}, invoices.created_at #{way}") }
  scope :by_amount,              lambda { |way='desc'| order("invoices.amount #{way}") }
  scope :by_user,                lambda { |way='desc'| joins(:user).order("users.name #{way}, users.email #{way}") }
  scope :by_invoice_items_count, lambda { |way='desc'| order("invoices.invoice_items_count #{way}") }

  def self.search(q)
    joins(:site, :user).where{
      (lower(user.email) =~ lower("%#{q}%")) |
      (lower(user.name) =~ lower("%#{q}%")) |
      (lower(site.hostname) =~ lower("%#{q}%")) |
      (lower(reference) =~ lower("%#{q}%"))
    }
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

