class InvoiceItem::Plan < InvoiceItem
  
  # =================
  # = Class Methods =
  # =================
  
  def self.open_invoice_item(site, date = Time.now.utc.to_date)
    puts site.billable_on
    puts site.user.billable_on
    return nil if site.archived? && site.billable_on < site.user.billable_on
    
    unless open_invoice_item = where(:invoice_id => site.user.open_invoice, :ended_on.gte => site.user.billable_on).first
      open_invoice_item = new(
        :site       => site,
        :item       => site.plan,
        :price      => site.plan.price,
        :started_on => site.billable_on,
        :ended_on   => site.billable_on + 1.send(site.plan.term_type)
      )
      open_invoice_item.calculate_and_set_amount
    end
    open_invoice_item
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def calculate_and_set_amount
    self.amount = price
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

