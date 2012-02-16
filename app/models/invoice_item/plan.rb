class InvoiceItem::Plan < InvoiceItem

  attr_accessor   :deduct
  attr_accessible :deduct

  # =================
  # = Class Methods =
  # =================

  def self.construct(attributes = {})
    instance = new(attributes)

    instance.set_deal
    instance.set_discounted_percentage
    instance.set_started_at_and_ended_at
    instance.set_price_and_amount

    instance
  end

  # ====================
  # = Instance Methods =
  # ====================

  def set_deal
    self.deal = deal_applicable? ? item.discounted?(site) : nil
  end

  def set_discounted_percentage
    self.discounted_percentage = deal_applicable? ? item.discounted_percentage(site) : 0
  end

  def set_started_at_and_ended_at
    self.started_at = deduct ? site.plan_cycle_started_at : (site.pending_plan_cycle_started_at || site.plan_cycle_started_at)
    self.ended_at   = deduct ? site.plan_cycle_ended_at : (site.pending_plan_cycle_ended_at || site.plan_cycle_ended_at)
  end

  def set_price_and_amount
    self.price = if deal_applicable?
      item.price(site)
    elsif deduct
      site.last_paid_plan_price
    else
      item.price
    end
    self.amount = (deduct ? -1 : 1) * price
  end

private

  def deal_applicable?
    !site.plan || site.skip_trial || (!deduct && site.plan.upgrade?(item))
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

