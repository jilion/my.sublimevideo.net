require 'spec_helper'

describe AddonPlanSettings do
  describe "Associations" do
    it { should belong_to(:addon_plan) }
    it { should belong_to(:plugin).class_name('App::Plugin') }
  end

  describe "Validations" do
    [:addon_plan, :plugin, :template].each do |attr|
      it { should allow_mass_assignment_of(attr).as(:admin) }
    end
  end

  describe '.get' do
    before do
      @addon = create(:addon, name: 'foo')
      @addon_plan = create(:addon_plan, name: 'bar', addon: @addon)
      @app_plugin = create(:app_plugin, addon: @addon, name: 'foo_bar')
      @addon_plan_settings = create(:addon_plan_settings, addon_plan: @addon_plan, plugin: @app_plugin)
    end

    it { described_class.get(@addon_plan, 'foo_bar').should eq @addon_plan_settings }
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

