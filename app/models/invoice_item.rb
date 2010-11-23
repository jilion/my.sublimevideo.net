class InvoiceItem < ActiveRecord::Base
  
  attr_accessible :site, :invoice, :item, :price, :amount, :started_at, :ended_at, :info
  serialize :info
  
  # ================
  # = Associations =
  # ================
  
  belongs_to :site
  belongs_to :invoice
  belongs_to :item, :polymorphic => true
  
  delegate :user, :to => :site
  
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
  validates :started_at, :presence => true
  validates :ended_at,   :presence => true
  validates :price,      :presence => true, :numericality => true
  validates :amount,     :presence => true, :numericality => true
  
  # =============
  # = Callbacks =
  # =============
  
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
#  id         :integer         not null, primary key
#  type       :string(255)
#  site_id    :integer
#  invoice_id :integer
#  item_type  :string(255)
#  item_id    :integer
#  started_at :datetime
#  ended_at   :datetime
#  price      :integer
#  amount     :integer
#  info       :text
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#  index_invoice_items_on_site_id                (site_id)
#

