module SiteModules::BillableItem
  extend ActiveSupport::Concern

  def app_design_is_active?(app_design)
    app_design.present? &&
    app_designs.where{ (billable_items.state >> BillableItem::ACTIVE_STATES) & (id == app_design.id) }.exists?
  end

  def addon_plan_is_active?(addon_plan)
    addon_plan.present? &&
    addon_plans.where{ (billable_items.state >> BillableItem::ACTIVE_STATES) & (id == addon_plan.id) }.exists?
  end

  def addon_plan_is_sponsored?(addon_plan)
    addon_plan.present? &&
    addon_plans.where{ (billable_items.state == 'sponsored') & (id == addon_plan.id) }.exists?
  end

  def addon_is_active?(addon)
    addon.present? &&
    addon_plans.where{ (billable_items.state >> BillableItem::ACTIVE_STATES) & (id >> addon.plans.pluck(:id)) }.exists?
  end

  def addon_plan_for_addon_name(addon_name)
    addon_plans.includes(:addon).where{ addons.name == addon_name }.first
  end

  def out_of_trial?(billable_item)
    if billable_item_activity = billable_item_activities.where(item_type: billable_item.class.to_s).where(item_id: billable_item.id).where(state: 'trial').first
      billable_item_activity.created_at <= BusinessModel.days_for_trial.days.ago
    else
      false
    end
  end

  def total_billable_items_price
    app_designs.where{ (billable_items.state >> %w[trial subscribed]) }.sum(:price) +
    addon_plans.where{ (billable_items.state >> %w[trial subscribed]) }.sum(:price)
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

