class AddonPlanSettings < ActiveRecord::Base
  serialize :template, Hash

  belongs_to :addon_plan
  belongs_to :plugin, class_name: 'App::Plugin', foreign_key: 'app_plugin_id'

  validates :addon_plan_id, uniqueness: { scope: :app_plugin_id }
end

# == Schema Information
#
# Table name: addon_plan_settings
#
#  addon_plan_id :integer          not null
#  app_plugin_id :integer
#  created_at    :datetime
#  id            :integer          not null, primary key
#  template      :text
#  updated_at    :datetime
#
# Indexes
#
#  index_addon_plan_settings_on_addon_plan_id_and_app_plugin_id  (addon_plan_id,app_plugin_id) UNIQUE
#

