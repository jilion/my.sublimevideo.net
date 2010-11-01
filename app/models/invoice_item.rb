class InvoiceItem < ActiveRecord::Base
  
  # attr_accessible ...
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :site
  belongs_to :invoice
  
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
  validates :price,      :presence => true
  
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
#  price                    :integer
#  overage_amount           :integer
#  overage_price            :integer
#  started_on               :date
#  ended_on                 :date
#  canceled_at              :datetime
#  refund                   :integer
#  refunded_invoice_item_id :integer
#  created_at               :datetime
#  updated_at               :datetime
#

