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
  
  validates :user,   :presence => true
  validates :amount, :numericality => true, :allow_nil => true
  validate  :uniqueness_of_open_invoice
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :open do
    event(:ready)  { transition :open => :unpaid }
    event(:charge) { transition :unpaid => [:paid, :failed], :failed => [:failed, :paid] }
    
    state :unpaid do
      validates :amount,    :presence => true
      validates :billed_on, :presence => true
    end
    
    state :paid do
    end
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.process_invoices_for_users_billable_on(date) # utc date!
    User.billable_on(date).each do |user|
      transaction do
        open_invoice = user.open_invoice
        open_invoice.calculate_and_set_amount # not saved if not chargeable
        
        if open_invoice.chargeable?
          open_invoice.billed_on = date
          open_invoice.ready
          open_invoice.delay.charge
          
          user.invoices.create # next open invoice
        end
        user.update_attribute(:billable_on, date + 1.month)
      end
    end
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def chargeable?
    
  end
  
  def calculate_and_set_amount
    
  end
  
private
  
  # validate
  def uniqueness_of_open_invoice
    if user && user.open_invoice.present?
      self.errors.add(:state, :uniqueness)
    end
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
#  billed_on  :date
#  paid_at    :datetime
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

