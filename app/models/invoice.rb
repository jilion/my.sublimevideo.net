StateMachine::Machine.ignore_method_conflicts = true

class Invoice < ActiveRecord::Base

  uniquify :reference, chars: Array('a'..'z') - ['o'] + Array('1'..'9')

  # ================
  # = Associations =
  # ================

  belongs_to :site
  has_one :user, through: :site

  # Invoice items
  has_many :invoice_items
  has_many :plan_invoice_items, conditions: { type: "InvoiceItem::Plan" }, class_name: "InvoiceItem"

  has_and_belongs_to_many :transactions

  delegate :user, to: :site

  # =============
  # = Callbacks =
  # =============

  before_create :set_customer_info, :set_site_info

  after_create :decrement_user_balance
  after_create do |record|
    record.succeed! if record.amount.zero?
  end

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

    before_transition on: :succeed, do: :set_paid_at
    after_transition  on: :succeed, do: :apply_site_pending_attributes, if: proc { |invoice| invoice.site.invoices.not_paid.empty? }
    after_transition  on: :succeed, do: :update_user_invoiced_amount
    after_transition  on: :succeed, do: :unsuspend_user, if: proc { |invoice| invoice.user.suspended? && invoice.user.invoices.not_paid.empty? }

    after_transition  on: :cancel, do: :increment_user_balance

    before_transition on: :fail, do: :set_last_failed_at
  end

  # ==========
  # = Scopes =
  # ==========

  scope :between,      lambda { |started_at, ended_at| where { (created_at >= started_at) & (created_at <= ended_at) } }
  scope :paid_between, lambda { |started_at, ended_at| where { (paid_at >= started_at) & (paid_at <= ended_at) } }

  scope :open,           where(state: 'open')
  scope :paid,           where(state: 'paid').includes(:site).where { sites.refunded_at == nil }
  scope :refunded,       where(state: 'paid').includes(:site).where { sites.refunded_at != nil }
  scope :failed,         where(state: 'failed')
  scope :waiting,        where(state: 'waiting')
  scope :canceled,       where(state: 'canceled')
  scope :open_or_failed, where(state: %w[open failed])
  scope :not_canceled,   where { state != 'canceled' }
  scope :not_paid,       where(state: %w[open waiting failed])
  scope :renew,          lambda { |bool=true| where(renew: bool) }
  scope :site_id,        lambda { |site_id| where(site_id: site_id) }
  scope :user_id,        lambda { |user_id| joins(:user).where { user.id == user_id } }

  # sort
  scope :by_id,                  lambda { |way='desc'| order(:id.send(way)) }
  scope :by_date,                lambda { |way='desc'| order(:created_at.send(way)) }
  scope :by_amount,              lambda { |way='desc'| order(:amount.send(way)) }
  scope :by_user,                lambda { |way='desc'| joins(:user).order(:name.send(way), :"users.email".send(way)) }
  scope :by_invoice_items_count, lambda { |way='desc'| order(:invoice_items_count.send(way)) }

  # search
  def self.search(q)
    joins(:site, :user).where {
      (lower(user.email) =~ lower("%#{q}%")) |
      (lower(user.name) =~ lower("%#{q}%")) |
      (lower(site.hostname) =~ lower("%#{q}%")) |
      (lower(reference) =~ lower("%#{q}%"))
    }
  end

  # =================
  # = Class Methods =
  # =================

  def self.construct(attributes = {})
    instance = new(attributes)

    instance.construct_invoice_items
    instance.set_invoice_items_amount
    instance.set_vat_rate_and_amount
    instance.set_balance_deduction_amount
    instance.set_amount

    instance
  end

  def self.total_revenue
    self.paid.sum(:amount)
  end

  def self.update_pending_dates_for_first_not_paid_invoices
    Invoice.not_paid.where(renew: [nil, false]).each do |invoice| # it returns first and upgrade invoices not already paid (never recurrent invoices)
      if invoice.first_site_invoice? # update only the first invoice (first paid plan)
        plan_invoice_item = invoice.invoice_items.first
        new_started_at    = Time.now.utc.midnight
        new_ended_at      = (new_started_at + invoice.site.advance_for_next_cycle_end(plan_invoice_item.item, new_started_at)).to_datetime.end_of_day

        plan_invoice_item.started_at = new_started_at
        plan_invoice_item.ended_at   = new_ended_at
        plan_invoice_item.save

        invoice.site.first_paid_plan_started_at    = new_started_at
        invoice.site.pending_plan_started_at       = new_started_at
        invoice.site.pending_plan_cycle_started_at = new_started_at
        invoice.site.pending_plan_cycle_ended_at   = new_ended_at
        invoice.site.save
      end
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  def to_param
    reference
  end

  def last_transaction
    transactions.order(:created_at.asc).last
  end

  def refunded?
    site.refunded_at?
  end

  def paid_plan_invoice_item
    plan_invoice_items.find { |pii| pii.amount > 0 }
  end

  # used in admin/invoices/timeline
  def paid_plan
    paid_plan_invoice_item.try(:item)
  end

  def first_site_invoice?
    first_site_invoice = site.invoices.not_canceled.by_date('asc').first
    first_site_invoice.nil? || self == first_site_invoice
  end

  def construct_invoice_items
    if site.pending_plan_id? && site.in_paid_plan? && site.plan.upgrade?(site.pending_plan)
      invoice_items << InvoiceItem::Plan.construct(invoice: self, item: Plan.find(site.plan_id), deduct: true)
    end
    invoice_items << InvoiceItem::Plan.construct(invoice: self, item: site.pending_plan || site.plan)
  end

  def set_invoice_items_amount
    self.invoice_items_amount = invoice_items.inject(0) { |sum, invoice_item| sum + invoice_item.amount }
  end

  def set_vat_rate_and_amount
    self.vat_rate   = Vat.for_country(user.billing_country)
    self.vat_amount = (invoice_items_amount * vat_rate).round
  end

  def set_balance_deduction_amount
    self.balance_deduction_amount = user.balance > 0 ? [user.balance, invoice_items_amount].min : 0
  end

  def set_amount
    self.amount = invoice_items_amount + vat_amount - balance_deduction_amount
  end

private

  # before_create
  def set_customer_info
    self.customer_full_name       = user.billing_name
    self.customer_email           = user.email
    self.customer_country         = user.billing_country
    self.customer_company_name    = user.company_name
    self.customer_billing_address = user.billing_address
  end

  # before_create
  def set_site_info
    self.site_hostname = site.hostname
  end

  # after_create
  def decrement_user_balance
    self.user.decrement!(:balance, balance_deduction_amount) unless self.reload.balance_deduction_amount.zero?
  end

  # before_transition on: :fail
  def set_last_failed_at
    self.last_failed_at = Time.now.utc
  end

  # before_transition on: :succeed
  def set_paid_at
    self.paid_at = Time.now.utc
  end

  # after_transition on: :succeed, if: proc { |invoice| invoice.site.invoices.not_paid.empty? }
  def apply_site_pending_attributes
    self.site.apply_pending_attributes
  end

  # after_transition on: :succeed
  def update_user_invoiced_amount
    self.user.last_invoiced_amount   = amount
    self.user.total_invoiced_amount += amount
    self.user.save
  end

  # after_transition on: :succeed
  def unsuspend_user
    self.user.unsuspend
  end

  # after_transition on: :cancel
  def increment_user_balance
    self.user.increment!(:balance, balance_deduction_amount) unless balance_deduction_amount.zero?
  end

end
# == Schema Information
#
# Table name: invoices
#
#  id                       :integer         not null, primary key
#  site_id                  :integer
#  reference                :string(255)
#  state                    :string(255)
#  customer_full_name       :string(255)
#  customer_email           :string(255)
#  customer_country         :string(255)
#  customer_company_name    :string(255)
#  site_hostname            :string(255)
#  amount                   :integer
#  vat_rate                 :float
#  vat_amount               :integer
#  invoice_items_amount     :integer
#  invoice_items_count      :integer         default(0)
#  transactions_count       :integer         default(0)
#  created_at               :datetime
#  updated_at               :datetime
#  paid_at                  :datetime
#  last_failed_at           :datetime
#  renew                    :boolean         default(FALSE)
#  balance_deduction_amount :integer         default(0)
#  customer_billing_address :text
#
# Indexes
#
#  index_invoices_on_reference  (reference) UNIQUE
#  index_invoices_on_site_id    (site_id)
#

