class InvoiceItem::Plan < InvoiceItem
  
  # =================
  # = Class Methods =
  # =================
  
  def self.open_invoice_items(site, date = Time.now.utc.to_date)
    open_invoice_items = where(:invoice_id => site.user.open_invoice).order(:started_on, :canceled_at).all
    if (!site.archived? || site.billable_on >= site.user.billable_on) && 
        (open_invoice_items.empty? || (open_invoice_items.present? && open_invoice_items.last.ended_on < site.user.billable_on))
      open_invoice_items << new(
        :site       => site,
        :item       => site.plan,
        :price      => site.plan.price,
        :amount     => site.plan.price,
        :started_on => site.billable_on,
        :ended_on   => site.billable_on + 1.send(site.plan.term_type)
      )
    end
    open_invoice_items
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  # def calculate_and_set_amount
  #   self.amount = price
  # end
  
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

