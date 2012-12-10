class App::SettingsTemplate < ActiveRecord::Base
  serialize :template, Hash

  attr_accessible :addon_plan, :plugin, :template, as: :admin

  belongs_to :addon_plan
  belongs_to :plugin, class_name: 'App::Plugin', foreign_key: 'app_plugin_id'

  validates :addon_plan_id, uniqueness: { scope: :app_plugin_id }

  def self.get(addon_name, addon_plan_name, app_plugin_name)
    Rails.cache.fetch("app_settings_template_#{addon_name}_#{addon_plan_name}_#{app_plugin_name}") do
      if addon_plan = AddonPlan.get(addon_name, addon_plan_name)
        joins(:plugin).where(addon_plan_id: addon_plan.id).where { plugin.name == app_plugin_name.to_s }.first
      end
    end
  end

end

# == Schema Information
#
# Table name: app_settings_templates
#
#  addon_plan_id :integer          not null
#  app_plugin_id :integer
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  template      :text
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_app_settings_templates_on_addon_plan_id_and_app_plugin_id  (addon_plan_id,app_plugin_id) UNIQUE
#

