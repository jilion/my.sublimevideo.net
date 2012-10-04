require 'spec_helper'

describe App::Settings do
  describe "Associations" do
    it { should belong_to(:addon_plan).class_name('Site::AddonPlan') }
    it { should belong_to(:plugin).class_name('App::Plugin') }
  end

  describe "Validations" do
    [:addon_plan, :plugin, :settings_template].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end
  end
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

