class Invoice < ActiveRecord::Base

  uniquify :reference, :chars => Array('a'..'z') - ['o'] + Array('1'..'9')

  # ================
  # = Associations =
  # ================

  belongs_to :site

  has_one :user, :through => :site

  has_many :invoice_items
  has_many :plan_invoice_items, conditions: { type: "InvoiceItem::Plan" }, :class_name => "InvoiceItem"

  has_and_belongs_to_many :transactions

  delegate :user, :to => :site

  # =============
  # = Callbacks =
  # =============

  before_validation :set_customer_infos, :set_site_infos, :on => :create

  # ===============
  # = Validations =
  # ===============

  validates :site,                 :presence => true # will change to :site
  validates :invoice_items_amount, :presence => true, :numericality => true
  validates :vat_rate,             :presence => true, :numericality => true
  validates :vat_amount,           :presence => true, :numericality => true
  validates :amount,               :presence => true, :numericality => true

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :open do
    event(:succeed) { transition [:open, :failed, :waiting] => :paid }
    event(:fail)    { transition [:open, :failed, :waiting] => :failed }
    event(:wait)    { transition [:open, :failed, :waiting] => :waiting }

    before_transition :on => :succeed, :do => :set_paid_at
    before_transition :on => :fail,    :do => :set_last_failed_at
    after_transition  :on => :succeed, :do => [:apply_pending_site_plan_changes, :update_user_invoiced_amount, :unsuspend_user, :push_new_revenue]
  end

  # ==========
  # = Scopes =
  # ==========

  scope :between, lambda { |started_at, ended_at| where(:created_at.gte => started_at, :created_at.lte => ended_at) }

  scope :open,           where(state: 'open')
  scope :failed,         where(state: 'failed')
  scope :open_or_failed, where(state: %w[open failed])
  scope :paid,           where(state: 'paid')
  scope :site_id,        lambda { |site_id| where(site_id: site_id) }
  scope :user_id,        lambda { |user_id| where(site_id: Site.where(user_id: user_id).map(&:id)) }

  # sort
  scope :by_amount,              lambda { |way='desc'| order(:amount.send(way)) }
  scope :by_invoice_items_count, lambda { |way='desc'| order(:invoice_items_count.send(way)) }

  scope :by_state,    lambda { |way='desc'| order(:state.send(way)) }
  scope :by_date,     lambda { |way='desc'| order(:created_at.send(way)) }

  # search
  def self.search(q)
    joins(:users).
    where(:lower.func(:email).matches % :lower.func("%#{q}%") |
          :lower.func(:first_name).matches % :lower.func("%#{q}%") |
          :lower.func(:last_name).matches % :lower.func("%#{q}%") |
          :lower.func(:reference).matches % :lower.func("%#{q}%"))
  end

  # =================
  # = Class Methods =
  # =================

  def self.build(attributes={})
    new(attributes).build
  end

  # ====================
  # = Instance Methods =
  # ====================

  def build
    build_invoice_items
    set_invoice_items_amount
    set_vat_rate_and_amount
    set_amount
    self
  end

  def to_param
    reference
  end

  def last_transaction
    transactions.order(:created_at).last
  end

private

  def build_invoice_items
    if site.pending_plan_id? && site.in_paid_plan?
      invoice_items << InvoiceItem::Plan.build(invoice: self, item: Plan.find(site.plan_id), deduct: true)
    end
    invoice_items << InvoiceItem::Plan.build(invoice: self, item: site.pending_plan || site.plan)
  end

  def set_invoice_items_amount
    self.invoice_items_amount = invoice_items.inject(0) { |sum, invoice_item| sum + invoice_item.amount }
  end

  def set_vat_rate_and_amount
    self.vat_rate   = Vat.for_country(user.country)
    self.vat_amount = (invoice_items_amount * vat_rate).round
  end

  def set_amount
    self.amount = invoice_items_amount + vat_amount
  end

  # before_validation :on => :create
  def set_customer_infos
    self.customer_full_name    ||= user.full_name
    self.customer_email        ||= user.email
    self.customer_country      ||= user.country
    self.customer_company_name ||= user.company_name
  end
  
  # before_validation :on => :create
  def set_site_infos
    self.site_hostname ||= site.hostname
  end

  # before_transition :on => :succeed
  def set_paid_at
    self.paid_at = Time.now.utc
  end

  # before_transition :on => :fail
  def set_last_failed_at
    self.last_failed_at = Time.now.utc
  end

  # after_transition :on => :succeed
  def apply_pending_site_plan_changes
    self.site.apply_pending_plan_changes
  end

  # after_transition :on => :succeed
  def update_user_invoiced_amount
    self.user.last_invoiced_amount = amount
    self.user.total_invoiced_amount += amount
    self.user.save
  end

  # after_transition :on => :succeed
  def unsuspend_user
    user.unsuspend if user.invoices.failed.empty?
  end

  # after_transition :on => :succeed
  def push_new_revenue
    # begin
    #  if Rails.env.production?
    #     plan_bought = self.invoice_items.detect { |invoice_item| invoice_item.amount > 0 }
    #     plan_deducted = self.invoice_items.detect { |invoice_item| invoice_item.amount < 0 }
    #     Ding.plan_added(plan_bought.item.title, plan_bought.item.cycle, plan_bought.amount)
    #     Ding.plan_removed(plan_deducted.title, plan_deducted.cycle, plan_deducted.price) if plan_deducted
    #   end
    # rescue
    #   # do nothing
    # end
  end

end



# == Schema Information
#
# Table name: invoices
#
#  id                    :integer         not null, primary key
#  site_id               :integer
#  reference             :string(255)
#  state                 :string(255)
#  customer_full_name    :string(255)
#  customer_email        :string(255)
#  customer_country      :string(255)
#  customer_company_name :string(255)
#  site_hostname         :string(255)
#  amount                :integer
#  vat_rate              :float
#  vat_amount            :integer
#  invoice_items_amount  :integer
#  invoice_items_count   :integer         default(0)
#  transactions_count    :integer         default(0)
#  created_at            :datetime
#  updated_at            :datetime
#  paid_at               :datetime
#  last_failed_at        :datetime
#
# Indexes
#
#  index_invoices_on_reference  (reference) UNIQUE
#  index_invoices_on_site_id    (site_id)
#

