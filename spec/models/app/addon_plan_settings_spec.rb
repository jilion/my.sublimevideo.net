require 'spec_helper'

describe AddonPlanSettings do
  describe "Associations" do
    it { should belong_to(:addon_plan) }
    it { should belong_to(:plugin).class_name('App::Plugin') }
  end
end

# == Schema Information
#
# Table name: addon_plan_settings
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
#  indexaddon_plan_settings_on_addon_plan_id_and_app_plugin_id  (addon_plan_id,app_plugin_id) UNIQUE
#

