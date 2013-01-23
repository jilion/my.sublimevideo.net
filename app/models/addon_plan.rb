require_dependency 'stage'

class AddonPlan < ActiveRecord::Base
  AVAILABILITIES = %w[hidden public custom] unless defined? AVAILABILITIES

  attr_accessible :addon, :name, :price, :availability, :required_stage, :stable_at, as: :admin

  belongs_to :addon
  has_many :components, through: :addon
  has_many :billable_items, as: :item
  has_many :settings_templates, class_name: 'App::SettingsTemplate'
  has_many :sites, through: :billable_items

  delegate :kind, to: :addon

  after_save :clear_caches

  validates :addon, :name, :price, presence: true
  validates :name, uniqueness: { scope: :addon_id }
  validates :availability, inclusion: AVAILABILITIES
  validates :required_stage, inclusion: Stage.stages
  validates :price, numericality: true

  scope :paid,    -> { where{ (stable_at != nil) & (price > 0) } }
  scope :custom,  -> { where{ availability == 'custom' } }
  scope :visible, -> { where{ availability != 'hidden' } }
  scope :public,  -> { where{ availability >> %w[hidden public] } }

  def self.free_addon_plans(options = {})
    options = { reject: [] }.merge(options)

    Addon.all.inject({}) do |hash, addon|
      if free_addon_plan = addon.free_plan
        if free_addon_plan.not_custom? && options[:reject].exclude?(free_addon_plan.addon.name)
          hash[addon.name.to_sym] = addon.free_plan.id
        end
      end
      hash
    end
  end

  def self.find_cached_by_addon_name_and_name(addon_name, addon_plan_name)
    Rails.cache.fetch [self, 'find_cached_by_addon_name_and_name', addon_name.to_s.dup, addon_plan_name.to_s.dup] do
      joins(:addon).where { (addon.name == addon_name.to_s) & (name == addon_plan_name.to_s) }.first
    end
  end

  def not_custom?
    availability.in?(%w[hidden public])
  end

  def beta?
    !stable_at?
  end

  def free?
    price.zero?
  end

  def available_for_subscription?(site)
    case availability
    when 'hidden'
      false
    when 'public'
      addon_plan_ids_except_myself = addon.plans.pluck(:id) - [id]
      !site.billable_items.addon_plans.where{ item_id >> addon_plan_ids_except_myself }.where(state: 'sponsored').exists?
    when 'custom'
      site.addon_plans.where(id: id).exists?
    end
  end

  def title
    I18n.t("addon_plans.#{addon.name}.#{name}")
  end

  def settings_template_for(design)
    dependant_design_id = addon.design_dependent? ? design.id : nil
    plugin_id = App::Plugin.where(addon_id: addon.id, app_design_id: dependant_design_id).first.try(:id)

    settings_templates.where(app_plugin_id: plugin_id).first
  end

  class << self
    alias_method :get, :find_cached_by_addon_name_and_name
  end

  private

  def clear_caches
    Rails.cache.clear [self.class, 'find_cached_by_addon_name_and_name', addon.name, name]
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
#  stable_at      :datetime
#  required_stage :string(255)      default("stable"), not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_addon_plans_on_addon_id           (addon_id)
#  index_addon_plans_on_addon_id_and_name  (addon_id,name) UNIQUE
#

