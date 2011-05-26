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

  validates :site,                 :presence => true
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
    event(:cancel)  { transition [:open, :failed] => :canceled }

    state :canceled do
      validate :ensure_first_invoice_of_site
    end

    before_transition :on => :succeed, :do => :set_paid_at
    after_transition  :on => :succeed, :do => :apply_pending_site_plan_changes, :if => proc { |invoice| invoice.user.invoices.not_paid.empty? }
    after_transition  :on => :succeed, :do => [:update_user_invoiced_amount, :unsuspend_user]

    before_transition :on => :fail,    :do => :set_last_failed_at
  end

  # ==========
  # = Scopes =
  # ==========

  scope :between, lambda { |started_at, ended_at| where(:created_at.gte => started_at, :created_at.lte => ended_at) }

  scope :open,                      where(state: 'open')
  scope :paid,                      where(state: 'paid').joins(:site).where(:sites => { :refunded_at => nil })
  scope :refunded,                  where(state: 'paid').joins(:site).where(:sites => { :refunded_at.ne => nil })
  scope :failed,                    where(state: 'failed')
  scope :waiting,                   where(state: 'waiting')
  scope :canceled,                  where(state: 'canceled')
  scope :open_or_failed,            where(state: %w[open failed])
  scope :not_canceled,              where(:state.ne => 'canceled')
  scope :not_paid,                  where(:state => %w[open waiting failed])
  scope :site_id,                   lambda { |site_id| where(site_id: site_id) }
  scope :user_id,                   lambda { |user_id| joins(:user).where(:users => { :id => user_id }) }

  # sort
  scope :by_date,                lambda { |way='desc'| order(:created_at.send(way)) }
  scope :by_amount,              lambda { |way='desc'| order(:amount.send(way)) }
  scope :by_user,                lambda { |way='desc'| joins(:user).order(:first_name.send(way), :"users.email".send(way)) }
  scope :by_invoice_items_count, lambda { |way='desc'| order(:invoice_items_count.send(way)) }

  # search
  def self.search(q)
    joins(:site, :user).
    where(:lower.func(:email).matches % :lower.func("%#{q}%") |
          :lower.func(:first_name).matches % :lower.func("%#{q}%") |
          :lower.func(:last_name).matches % :lower.func("%#{q}%") |
          :lower.func(:"sites.hostname").matches % :lower.func("%#{q}%") |
          :lower.func(:reference).matches % :lower.func("%#{q}%"))
  end

  # =================
  # = Class Methods =
  # =================

  def self.build(attributes={})
    new(attributes).build
  end

  def self.total_revenue
    self.paid.sum(:amount)
  end

  def self.delay_update_pending_dates_for_first_not_paid_invoices
    unless Delayed::Job.already_delayed?('%Invoice%update_pending_dates_for_first_not_paid_invoices%')
      delay(:priority => 2, :run_at => Time.now.utc.tomorrow.midnight).update_pending_dates_for_first_not_paid_invoices
    end
  end

  def self.update_pending_dates_for_first_not_paid_invoices
    Invoice.not_paid.where(renew: [nil, false]).each do |invoice| # it returns first and upgrade invoices not already paid (never recurrent invoices)
      if invoice == invoice.site.invoices.by_date('asc').first # update only the first invoice (first paid plan)
        plan_invoice_item = invoice.invoice_items.first
        new_started_at    = Time.now.utc.midnight
        new_ended_at      = (new_started_at + invoice.site.advance_for_next_cycle_end(plan_invoice_item.item, new_started_at)).to_datetime.end_of_day

        plan_invoice_item.started_at = new_started_at
        plan_invoice_item.ended_at   = new_ended_at
        plan_invoice_item.save

        invoice.site.pending_plan_started_at       = new_started_at
        invoice.site.pending_plan_cycle_started_at = new_started_at
        invoice.site.pending_plan_cycle_ended_at   = new_ended_at
        invoice.site.save
      end
    end
    delay_update_pending_dates_for_first_not_paid_invoices
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

  def refunded?
    site.refunded_at?
  end

  def paid_plan_invoice_item
    plan_invoice_items.detect { |pii| pii.amount > 0 }
  end

  # used in admin/invoices/timeline
  def paid_plan
    paid_plan_invoice_item.try(:item)
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

  # validate (canceled state)
  def ensure_first_invoice_of_site
    if site.first_paid_plan_started_at?
      self.errors.add(:base, :not_first_invoice)
    end
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

  # before_transition :on => :fail
  def set_last_failed_at
    self.last_failed_at = Time.now.utc
  end

  # before_transition :on => :succeed
  def set_paid_at
    self.paid_at = Time.now.utc
  end

  # after_transition :on => :succeed, :if => proc { |invoice| invoice.user.invoices.not_paid.empty? }
  def apply_pending_site_plan_changes
    if user.invoices.not_paid.empty?
      self.site.apply_pending_plan_changes
    else
      true # don't apply pending dates if not-paid invoices are still present
    end
  end

  # after_transition :on => :succeed
  def update_user_invoiced_amount
    self.user.last_invoiced_amount   = amount
    self.user.total_invoiced_amount += amount
    self.user.save
  end

  # after_transition :on => :succeed
  def unsuspend_user
    if user.suspended? && user.invoices.not_paid.empty?
      user.unsuspend
    else
      true
    end
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
#  renew                 :boolean         default(FALSE)
#
# Indexes
#
#  index_invoices_on_reference  (reference) UNIQUE
#  index_invoices_on_site_id    (site_id)
#

