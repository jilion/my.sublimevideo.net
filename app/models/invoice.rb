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
  validate  :uniqueness_of_next_invoice
  
  # =============
  # = Callbacks =
  # =============
  
  after_create :create_invoice_items
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :next do
    # event(:prepare_for_charging) { transition :next => :ready }
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
      billable_invoice = self.billable_invoice(user)
      billable_invoice.calculate_overages
      billable_invoice.calculate_refund
      billable_invoice.ended_on = date + 1.month
      billable_invoice.state = 'ready'
      
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
  
  def calculate_overages
    # easy
  end
  
  def calculate_refund
    @refund = 0
    billable_invoice.invoice_items.canceled.each do |canceled_invoice_item|
      @refund += canceled_invoice_item.calculate_pro_rata
      # calculate_pro_rata should do (ended_on - canceled_on) * price_per_day_of_the_invoice_item
    end
  end
  
private
  
  # validate
  def uniqueness_of_next_invoice
    if user && user.next_invoice.present?
      self.errors.add(:state, :uniqueness)
    end
  end
  
  # after_create
  def create_invoice_items
    return # don't execute for now
    # take all invoice_item that have canceled_on == nil of the last invoice (the one we just set as ready)
    # create new invoice_item from them for the next invoice
    user.last_invoice.invoice_items.not_canceled.each do |invoice_item|
      self.items.build(
        :site_id => invoice_item.site_id,
        :item_type => invoice_item.item_type,
        :item_id => invoice_item.item_id,
        :started_on => self.started_on,
        :price => invoice_item.item.price
      )
    end
    self.save
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

