class InvoiceItem::Refund < InvoiceItem
  
  # belongs_to :refunded_invoice_item, :class_name => "InvoiceItem"
  
  # =================
  # = Class Methods =
  # =================
  
  def self.open_invoice_items(site, date = Time.now.utc.to_date)
    where(:invoice_id => site.user.open_invoice).order(:started_on).all
  end
  
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
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#  index_invoice_items_on_site_id                (site_id)
#

