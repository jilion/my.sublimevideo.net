class InvoiceItem::Addon < InvoiceItem
  
  attr_accessible :lifetime
  attr_accessor :lifetime
  
  # =================
  # = Class Methods =
  # =================
  
  def self.build(attributes = {})
    invoice_item = new(attributes)
    invoice_item.set_item_and_price
    invoice_item.set_started_at_and_ended_at
    invoice_item.set_amount
    invoice_item
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def set_item_and_price
    self.item  = lifetime.item
    self.price = lifetime.item.price
  end
  
  def set_started_at_and_ended_at
    self.started_at = [lifetime.created_at, site.activated_at, invoice.started_at].compact.max
    self.ended_at   = lifetime.deleted_at || site.archived_at || invoice.ended_at
  end
  
  def set_amount
    self.amount = (price * percentage).round
  end
  
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

