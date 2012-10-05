module SiteModules::Addon
  extend ActiveSupport::Concern

  def addon_plan_is_active?(addon_plan)
    addon_plan.present? &&
    addon_plans.where{ (billable_items.state >> BillableItem::ACTIVE_STATES) & (id == addon_plan.id) }.exists?
  end

  def addon_is_active?(cat)
    persisted? && addons.active.where{ category == cat }.exists?
  end

end

# == Schema Information
#
# Table name: addons
#
#  context          :text             not null
#  created_at       :datetime         not null
#  design_dependent :boolean          not null
#  id               :integer          not null, primary key
#  name             :string(255)      not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_addons_on_name  (name) UNIQUE
#

