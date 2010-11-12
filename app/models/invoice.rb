class Invoice < ActiveRecord::Base
  
  attr_accessible :user_id, :started_on, :ended_on
  
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
  
  validates :user,       :presence => true
  validates :started_on, :presence => true
  validates :amount,     :numericality => true, :allow_nil => true
  validate :uniqueness_of_next_invoice
  
  # =============
  # = Callbacks =
  # =============
  
  before_create :create_invoice_items
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :next do
    event(:prepare_for_charging) { transition :next => :ready }
    event(:archive) { transition :ready => :archived }
    
    state :ready do
      validates :amount, :presence => true
      validates :ended_on, :presence => true
    end
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.process_invoices_for_users_billable_on(date) # utc date!
    User.billable_on(date).each do |user|
      billable_invoice(user)
      billable_invoice.calculate_overrage
      billable_invoice.calculate_refund
      billable_invoice.ended_on = date + 1.month
      billable_invoice.ready
      
      next_invoice = user.invoices.create(:started_on => date + 1.month)
      user.next_invoiced_on = date + 1.month
    end
  end
  
  def self.billable_invoice(user)
    user.next_invoice || user.invoices.create(:started_on => date)
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
private
  
  # validate
  def uniqueness_of_next_invoice
    if user && user.next_invoice.present?
      self.errors.add(:state, :uniqueness)
    end
  end
  
  def create_invoice_items
    
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
#  started_on :date
#  ended_on   :date
#  charged_at :datetime
#  attempts   :integer         default(0)
#  last_error :string(255)
#  failed_at  :datetime
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoices_on_user_id  (user_id)
#

