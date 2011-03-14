class Invoice < ActiveRecord::Base
  extend ActiveSupport::Memoizable

  uniquify :reference, :chars => Array('a'..'z') - ['o'] + Array('1'..'9')

  # ================
  # = Associations =
  # ================

  belongs_to :site
  has_many :invoice_items

  has_many :plan_invoice_items, conditions: { type: "InvoiceItem::Plan" }, :class_name => "InvoiceItem"

  has_and_belongs_to_many :transactions

  delegate :user, :to => :site

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
    state :failed
    state :paid
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
  scope :by_attempts, lambda { |way='desc'| order(:attempts.send(way)) }
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

  def self.complete_invoice(site_id)
    site = Site.find(site_id)
    build(site: site).complete if site
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

  def to_param
    reference
  end

  def total_invoice_items_amount
    invoice_items.inject(0) { |sum, invoice_item| sum + invoice_item.amount }
  end
  memoize :total_invoice_items_amount

private

  def build_invoice_items
    if site.instant_charging? && site.plan_id_changed? && site.plan_id_was
      plan_was = Plan.find(site.plan_id_was)
      invoice_items << InvoiceItem::Plan.build(invoice: self, item: plan_was, refund: true)
    end
    invoice_items << InvoiceItem::Plan.build(invoice: self)
  end

  def set_invoice_items_amount
    self.invoice_items_amount = total_invoice_items_amount
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

  # after_transition :on => :complete
  def update_user_invoiced_amount
    self.user.last_invoiced_amount = amount
    self.user.total_invoiced_amount += amount
    self.user.save
  end

end


# == Schema Information
#
# Table name: invoices
#
#  id                      :integer         not null, primary key
#  site_id                 :integer
#  reference               :string(255)
#  state                   :string(255)
#  amount                  :integer
#  vat_rate                :float
#  vat_amount              :integer
#  discount_rate           :float
#  discount_amount         :integer
#  invoice_items_amount    :integer
#  charging_delayed_job_id :integer
#  invoice_items_count     :integer         default(0)
#  transactions_count      :integer         default(0)
#  created_at              :datetime
#  updated_at              :datetime
#  paid_at                 :datetime
#  failed_at               :datetime
#
# Indexes
#
#  index_invoices_on_site_id  (site_id)
#

