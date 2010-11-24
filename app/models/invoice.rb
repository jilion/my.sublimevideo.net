class Invoice < ActiveRecord::Base
  
  uniquify :reference, :chars => Array('A'..'Z') + Array('1'..'9')
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :user
  has_many :invoice_items
  
  # ==========
  # = Scopes =
  # ==========
  
  # ===============
  # = Validations =
  # ===============
  
  validates :user, :presence => true
  validates :started_at, :presence => true
  validates :ended_at, :presence => true
  validates :amount, :numericality => true, :allow_nil => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :open do
    state :unpaid do
      validates :amount, :presence => true
    end
    
    event(:complete) { transition :open => :unpaid }
    event(:charge)   { transition :unpaid => [:paid, :failed], :failed => [:failed, :paid] }
    
    after_transition  :to => :complete, :do => :delay_charge
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.build(attributes = {})
    invoice = new(attributes)
    invoice.build_invoice_items
    invoice
  end
  
  def self.complete_invoices_for_billable_users(started_at, ended_at) # utc dates!
    User.billable(started_at, ended_at).each do |user|
      invoice = build(:user => site, :started_at => started_at, :ended_at => ended_at)
      invoice.set_amount
      invoice.complete
    end
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def build_invoice_items
    user.sites.includes(:versions).billable(started_at, ended_at).each do |site|
      past_site = site.version_at(ended_at)
      invoice_items << InvoiceItem::Plan.build(:site => past_site, :invoice => self)
      invoice_items << InvoiceItem::Overage.build(:site => past_site, :invoice => self)
    end
  end
  
  def minutes
    (ended_at - started_at).to_f / 60
  end
  
  def set_amount
    
  end
  
  def delay_charge
    # ...
  end
  
end


# == Schema Information
#
# Table name: invoices
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  reference  :string(255)
#  state      :string(255)
#  amount     :integer
#  started_at :datetime
#  ended_at   :datetime
#  paid_at    :datetime
#  attempts   :integer         default(0)
#  last_error :string(255)
#  failed_at  :datetime
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoices_on_user_id                 (user_id)
#  index_invoices_on_user_id_and_ended_at    (user_id,ended_at) UNIQUE
#  index_invoices_on_user_id_and_started_at  (user_id,started_at) UNIQUE
#

