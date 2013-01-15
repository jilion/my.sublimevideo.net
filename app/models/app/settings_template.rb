class App::SettingsTemplate < ActiveRecord::Base
  serialize :template, Hash

  attr_accessible :addon_plan, :plugin, :template, as: :admin

  belongs_to :addon_plan
  belongs_to :plugin, class_name: 'App::Plugin', foreign_key: 'app_plugin_id'

  after_save :clear_caches

  validates :addon_plan_id, uniqueness: { scope: :app_plugin_id }

  def self.find_cached_by_addon_plan_and_plugin_name(addon_plan, plugin_name = nil)
    if plugin_name.blank?
      Rails.cache.fetch [self, 'find_cached_by_addon_plan', addon_plan.to_s.dup] do
        addon_plan.settings_templates.first
      end
    else
      Rails.cache.fetch [self, 'find_cached_by_addon_plan_and_plugin_name', addon_plan.to_s.dup, plugin_name.to_s.dup] do
        addon_plan.settings_templates.includes(:plugin).where { plugin.name == plugin_name.to_s }.first
      end
    end
  end

  class << self
    alias_method :get, :find_cached_by_addon_plan_and_plugin_name
  end

  private

  def clear_caches
    Rails.cache.clear [self.class, 'find_cached_by_addon_plan', addon_plan]
    Rails.cache.clear [self.class, 'find_cached_by_addon_plan_and_plugin_name', addon_plan, plugin.try(:name)]
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

