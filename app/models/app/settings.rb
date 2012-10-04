class App::Settings < ActiveRecord::Base
  attr_accessible :addon_plan, :plugin, :settings_template, as: :admin

  belongs_to :addon_plan, class_name: 'Site::AddonPlan', foreign_key: 'site_addon_plan_id'
  belongs_to :plugin, class_name: 'App::Plugin', foreign_key: 'app_plugin_id'
end

# == Schema Information
#
# Table name: app_settings
#
#  app_plugin_id      :integer
#  created_at         :datetime         not null
#  id                 :integer          not null, primary key
#  settings_template  :hstore
#  site_addon_plan_id :integer          not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_app_settings_on_site_addon_plan_id_and_app_plugin_id  (site_addon_plan_id,app_plugin_id)
#
