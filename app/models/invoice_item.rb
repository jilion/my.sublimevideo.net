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
  
  validates :overage_amount, :numericality => true, :allow_nil => true
  validates :overage_price,  :numericality => true, :allow_nil => true
  validates :refund,         :numericality => true, :allow_nil => true
  
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
#  id                       :integer         not null, primary key
#  site_id                  :integer
#  invoice_id               :integer
#  item_type                :string(255)
#  item_id                  :integer
#  started_on               :date
#  ended_on                 :date
#  canceled_at              :datetime
#  price                    :integer
#  overage_amount           :integer         default(0)
#  overage_price            :integer
#  refund                   :integer         default(0)
#  refunded_invoice_item_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#  index_invoice_items_on_site_id                (site_id)
#
