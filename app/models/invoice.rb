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
    state :unpaid# do
    #   validates :amount, :presence => true
    # end
    
    event(:complete) { transition :open => :unpaid }
    event(:charge)   { transition :unpaid => [:paid, :failed], :failed => [:failed, :paid] }
    
    before_transition :on => :complete, :do => :set_completed_at
    after_transition :on => :complete, :do => :delay_charge
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
  
  # pending
  def self.complete_invoices_for_billable_users(started_at, ended_at) # utc dates!
    User.billable(started_at, ended_at).each do |user|
      invoice = build(:user => user, :started_at => started_at, :ended_at => ended_at)
      invoice.complete
    end
  end
  
  def self.charge(invoice_id)
    invoice = find(invoice_id)
    
    
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
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
  
  # after_transition :on => :complete
  def delay_charge
    # if amount > 0
      delayed_job = self.class.delay(:run_at => 5.days.from_now).charge(self.id)
      self.update_attribute(:charging_delayed_job_id, delayed_job.id)
    # end
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

