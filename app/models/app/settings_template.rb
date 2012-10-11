class App::SettingsTemplate < ActiveRecord::Base
  attr_accessible :addon_plan, :plugin, :template, as: :admin

  belongs_to :addon_plan
  belongs_to :plugin, class_name: 'App::Plugin', foreign_key: 'app_plugin_id'

  validates :addon_plan_id, uniqueness: { scope: :app_plugin_id }
end

# == Schema Information
#
# Table name: app_settings_templates
#
#  addon_plan_id :integer          not null
#  app_plugin_id :integer
#  created_at    :datetime         not null
#  id            :integer          not null, primary key
#  template      :hstore
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_app_settings_templates_on_addon_plan_id_and_app_plugin_id  (addon_plan_id,app_plugin_id) UNIQUE
#
