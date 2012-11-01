require_dependency 'stage'

class AddonPlan < ActiveRecord::Base
  AVAILABILITIES = %w[hidden public custom] unless defined? AVAILABILITIES

  attr_accessible :addon, :name, :price, :availability, :required_stage, :public_at, as: :admin

  belongs_to :addon
  has_many :components, through: :addon
  has_many :billable_items, as: :item
  has_many :settings_templates, class_name: 'App::SettingsTemplate'

  delegate :kind, to: :addon

  validates :addon, :name, :price, presence: true
  validates :name, uniqueness: { scope: :addon_id }
  validates :availability, inclusion: AVAILABILITIES
  validates :required_stage, inclusion: Stage::STAGES
  validates :price, numericality: true

  scope :paid, -> { where{ (public_at != nil) & (price > 0) } }

  def self.free_addon_plans(options = {})
    options = { reject: [] }.merge(options)

    Addon.all.inject({}) do |hash, addon|
      if free_addon_plan = addon.free_plan
        unless free_addon_plan.availability == 'custom' || options[:reject].include?(free_addon_plan.addon.name)
          hash[addon.name.to_sym] = addon.free_plan.id
        end
      end
      hash
    end
  end

  def self.get(addon_name, addon_plan_name)
    Rails.cache.fetch("addon_plan_#{addon_name}_#{addon_plan_name}") { joins(:addon).where { (addon.name == addon_name) & (name == addon_plan_name) }.first }
  end

  def available?(site)
    case availability
    when 'hidden'
      false
    when 'public'
      addon_plan_ids_expect_myself = addon.plans.pluck(:id) - [id]
      !site.billable_items.addon_plans.where{ item_id >> addon_plan_ids_expect_myself }.where(state: 'sponsored').exists?
    when 'custom'
      site.addon_plans.where(id: id).exists?
    end
  end

  def settings_template_for(design)
    App::SettingsTemplate.where(
      app_plugin_id: App::Plugin.where(addon_id: addon.id, app_design_id: addon.design_dependent? ? design.id : nil).first.try(:id),
      addon_plan_id: id).first
  end

  def beta?
    !public_at?
  end

  def free?
    beta? || price.zero?
  end

  def title
    I18n.t("addon_plans.#{addon.name}.#{name}")
  end
end

# == Schema Information
#
# Table name: addon_plans
#
#  addon_id       :integer          not null
#  availability   :string(255)      not null
#  created_at     :datetime         not null
#  id             :integer          not null, primary key
#  name           :string(255)      not null
#  price          :integer          not null
#  public_at      :datetime
#  required_stage :string(255)      default("stable"), not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_addon_plans_on_addon_id           (addon_id)
#  index_addon_plans_on_addon_id_and_name  (addon_id,name) UNIQUE
#

