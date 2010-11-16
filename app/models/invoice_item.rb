class InvoiceItem < ActiveRecord::Base
  
  attr_accessible :site_id, :item_type, :item_id, :started_on, :ended_on, :price, :overage_amount, :overage_price, :refund, :refunded_invoice_item_id
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :site
  belongs_to :invoice
  belongs_to :item, :polymorphic => true
  belongs_to :refunded_invoice_item, :class_name => "InvoiceItem"
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :not_canceled, where(:canceled_at => nil) # probably change canceled_at to canceled_on
  scope :canceled, where(:canceled_at.ne => nil)
  
  # ===============
  # = Validations =
  # ===============
  
  validates :site,       :presence => true
  validates :invoice,    :presence => true
  validates :item_type,  :presence => true
  validates :item_id,    :presence => true
  validates :started_on, :presence => true
  validates :ended_on,   :presence => true
  validates :price,      :presence => true, :numericality => true
  validates :amount, :numericality => true, :allow_nil => true
  
  # =============
  # = Callbacks =
  # =============
  
  # =================
  # = State Machine =
  # =================
  
  # =================
  # = Class Methods =
  # =================
  
  # ====================
  # = Instance Methods =
  # ====================
  
end


# == Schema Information
#
# Table name: invoice_items
#
#  id          :integer         not null, primary key
#  type        :string(255)
#  site_id     :integer
#  invoice_id  :integer
#  item_type   :string(255)
#  item_id     :integer
#  started_on  :date
#  ended_on    :date
#  canceled_at :datetime
#  price       :integer
#  amount      :integer
#  info        :text
#  created_at  :datetime
#  updated_at  :datetime
#

