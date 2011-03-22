class InvoiceItem::Plan < InvoiceItem

  attr_accessor   :refund
  attr_accessible :refund

  # =================
  # = Class Methods =
  # =================

  def self.build(attributes={})
    new(attributes).build
  end

  # ====================
  # = Instance Methods =
  # ====================

  def build
    set_started_at_and_ended_at
    set_price_and_amount
    self
  end

private

  def set_started_at_and_ended_at
    self.started_at = refund ? site.plan_cycle_started_at : site.pending_plan_cycle_started_at || site.plan_cycle_started_at
    self.ended_at   = refund ? site.plan_cycle_ended_at : site.pending_plan_cycle_ended_at || site.plan_cycle_ended_at
  end

  def set_price_and_amount
    self.price  = item.price
    self.amount = (refund ? -1 : 1) * price
  end

end


# == Schema Information
#
# Table name: invoice_items
#
#  id         :integer         not null, primary key
#  type       :string(255)
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
#

