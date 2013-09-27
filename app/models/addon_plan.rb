class AddonPlan < BillableEntity
  belongs_to :addon
  has_many :components, through: :addon
  has_many :settings, class_name: 'AddonPlanSettings'

  delegate :kind, :free_plan, to: :addon
  delegate :name, to: :addon, prefix: true

  after_save :clear_caches

  validates :addon, :name, :price, presence: true
  validates :name, uniqueness: { scope: :addon_id }

  def self.find_cached_by_addon_name_and_name(addon_name, addon_plan_name)
    Rails.cache.fetch [self, 'find_cached_by_addon_name_and_name', addon_name.to_s.dup, addon_plan_name.to_s.dup] do
      joins(:addon).where("addons.name = ? AND addon_plans.name = ?", addon_name.to_s, addon_plan_name.to_s).first
    end
  end
  class << self
    alias_method :get, :find_cached_by_addon_name_and_name
  end

  def self.free_addon_plans(options = {})
    options.reverse_merge!(reject: [])

    AddonPlan.includes(:addon).where.not(addons: { name: options.fetch(:reject) }).references(:addons).not_custom.where(price: 0)
  end

  def available_for_subscription?(site)
    case availability
    when 'hidden'
      false
    when 'public'
      addon_plan_ids_except_myself = addon.plans.pluck(:id) - [id]
      !site.billable_items.addon_plans.where(item_id: addon_plan_ids_except_myself).state('sponsored').exists?
    when 'custom'
      site.addon_plans.where(id: id).exists?
    end
  end

  def title
    I18n.t("addon_plans.#{addon_name}.#{name}")
  end

  def settings_for(design)
    dependant_design_id = addon.design_dependent? ? design.id : nil
    plugin_id = App::Plugin.where(addon_id: addon.id, design_id: dependant_design_id).first.try(:id)

    settings.where(app_plugin_id: plugin_id).first
  end

  private

  def clear_caches
    Rails.cache.clear [self.class, 'find_cached_by_addon_name_and_name', addon_name, name]
  end
end

# == Schema Information
#
# Table name: addon_plans
#
#  addon_id       :integer          not null
#  availability   :string(255)      not null
#  created_at     :datetime
#  id             :integer          not null, primary key
#  name           :string(255)      not null
#  price          :integer          not null
#  required_stage :string(255)      default("stable"), not null
#  stable_at      :datetime
#  updated_at     :datetime
#
# Indexes
#
#  index_addon_plans_on_addon_id           (addon_id)
#  index_addon_plans_on_addon_id_and_name  (addon_id,name) UNIQUE
#

