class Invoice < ActiveRecord::Base
  
  attr_accessible :user_id
  
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
  validates :amount,     :numericality => true, :allow_nil => true
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
      validates :closed_on, :presence => true
    end
  end
  
  # =================
  # = Class Methods =
  # =================
  
  def self.process_invoices_for_users_billable_on(date) # utc date!
    User.billable_on(date).each do |user|
      transaction do
        open_invoice = self.open_invoice(user)
        open_invoice.create_invoice_items_for_plans
        open_invoice.calculate_plans_overages
        open_invoice.calculate_addons_price
        
        if open_invoice.chargeable?
          open_invoice.billed_on = date
          open_invoice.ready
          open_invoice.delay.charge
          
          next_open_invoice = user.invoices.create
          next_open_invoice.create_invoice_items_for_addons
        else
          open_invoice.create_invoice_items_for_addons
        end
        user.update_attribute(:billable_on, date + 1.month)
      end
    end
  end
  
  def self.open_invoice(user)
    user.open_invoice || user.invoices.create
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def calculate_refund
    @refund = 0
    billable_invoice.invoice_items.canceled.each do |canceled_invoice_item|
      @refund += canceled_invoice_item.calculate_pro_rata
      # calculate_pro_rata should do (ended_on - canceled_on) * price_per_day_of_the_invoice_item
    end
  end
  
  def create_invoice_items_for_plans
  end
  
  def create_invoice_items_for_addons
  end
  
  def calculate_plans_overages
  end
  
  def calculate_addons_price
  end
  
  def chargeable?
    
  end
  
private
  
  # validate
  def uniqueness_of_open_invoice
    if user && user.open_invoice.present?
      self.errors.add(:state, :uniqueness)
    end
  end
  
  # # after_create
  # def create_invoice_items
    # return # don't execute for now
    # # take all invoice_item that have canceled_on == nil of the last invoice (the one we just set as ready)
    # # create new invoice_item from them for the next invoice
    # user.last_invoice.invoice_items.not_canceled.each do |invoice_item|
    #   self.items.build(
    #     :site_id => invoice_item.site_id,
    #     :item_type => invoice_item.item_type,
    #     :item_id => invoice_item.item_id,
    #     :started_on => self.started_on,
    #     :price => invoice_item.item.price
    #   )
    # end
    # self.save
  # end
  
  
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
#  closed_on  :date
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

