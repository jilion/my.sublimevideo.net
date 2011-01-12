class InvoiceItem::Overage < InvoiceItem

  # =================
  # = Class Methods =
  # =================

  def self.build(attributes = {})
    new(attributes.merge(:info => {})).build
  end

  # ====================
  # = Instance Methods =
  # ====================

  def build
    set_item_and_price
    set_started_at_and_ended_at
    set_player_hits_used
    set_overage_blocks
    set_amount
    self
  end

  def prorated_plan_player_hits
    (info[:plan_player_hits] * percentage).round
  end

private

  def set_item_and_price
    self.item                    = site.plan
    self.price                   = site.plan.overage_price
    self.info[:plan_player_hits] = site.plan.player_hits
  end

  def set_started_at_and_ended_at
    self.started_at = [site.activated_at, invoice.started_at].max
    self.ended_at   = site.archived_at || invoice.ended_at
  end

  def set_player_hits_used
    self.info[:player_hits_used] = SiteUsage.where(:site_id => site.id).between(started_at.midnight, ended_at.end_of_day).find.sum do |su|
      su.main_player_hits + su.main_player_hits_cached + su.extra_player_hits + su.extra_player_hits_cached
    end
  end

  def set_overage_blocks
    self.info[:overage_blocks] = [((info[:player_hits_used] - prorated_plan_player_hits).to_f / ::Plan::OVERAGES_PLAYER_HITS_BLOCK).ceil, 0].max
  end

  def set_amount
    self.amount = price * info[:overage_blocks]
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

