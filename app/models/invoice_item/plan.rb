class InvoiceItem::Plan < InvoiceItem

  attr_accessor   :deduct
  attr_accessible :deduct

  # =================
  # = Class Methods =
  # =================

  def self.build(attributes = {})
    new(attributes).build
  end

  # ====================
  # = Instance Methods =
  # ====================

  def build
    set_discounted_percentage
    set_started_at_and_ended_at
    set_price_and_amount
    self
  end

private

  def set_discounted_percentage
    self.discounted_percentage = item.discounted_percentage if !deduct && item.discounted?(site)
  end

  def set_started_at_and_ended_at
    self.started_at = deduct ? site.plan_cycle_started_at : (site.pending_plan_cycle_started_at || site.plan_cycle_started_at)
    self.ended_at   = deduct ? site.plan_cycle_ended_at : (site.pending_plan_cycle_ended_at || site.plan_cycle_ended_at)
  end

  def set_price_and_amount
    self.price  = deduct ? site.last_paid_plan_price : item.price
    self.amount = (deduct ? -1 : 1) * price
  end

end



# == Schema Information
#
# Table name: invoice_items
#
#  id                    :integer         not null, primary key
#  type                  :string(255)
#  invoice_id            :integer
#  item_type             :string(255)
#  item_id               :integer
#  started_at            :datetime
#  ended_at              :datetime
#  discounted_percentage :float
#  price                 :integer
#  amount                :integer
#  created_at            :datetime
#  updated_at            :datetime
#
# Indexes
#
#  index_invoice_items_on_invoice_id             (invoice_id)
#  index_invoice_items_on_item_type_and_item_id  (item_type,item_id)
#

