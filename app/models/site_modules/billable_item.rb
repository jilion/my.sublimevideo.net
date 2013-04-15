module SiteModules::BillableItem
  extend ActiveSupport::Concern

  def subscribed_to?(item)
    billable_items.with_item(item).state(BillableItem::ACTIVE_STATES).exists?
  end

  def sponsored_to?(item)
    billable_items.with_item(item).state('sponsored').exists?
  end

  def addon_plan_for_addon_name(addon_name)
    addon_plans.includes(:addon).where { addons.name == addon_name }.first
  end

  def total_billable_items_price
    app_designs.where { (billable_items.state >> %w[trial subscribed]) }.sum(:price) +
    addon_plans.where { (billable_items.state >> %w[trial subscribed]) }.sum(:price)
  end

end

# == Schema Information
#
# Table name: billable_items
#
#  created_at :datetime         not null
#  id         :integer          not null, primary key
#  item_id    :integer          not null
#  item_type  :string(255)      not null
#  site_id    :integer          not null
#  state      :string(255)      not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_billable_items_on_item_type_and_item_id              (item_type,item_id)
#  index_billable_items_on_item_type_and_item_id_and_site_id  (item_type,item_id,site_id) UNIQUE
#  index_billable_items_on_site_id                            (site_id)
#

