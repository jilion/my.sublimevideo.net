class InvoiceItem::Refund < InvoiceItem
  
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

