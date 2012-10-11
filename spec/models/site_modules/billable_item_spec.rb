require "spec_helper"

describe SiteModules::BillableItem, :addons do
  let(:site) { create(:site) }
  before do
    create(:billable_item, site: site, item: @classic_design, state: 'subscribed')
    create(:billable_item, site: site, item: @light_design, state: 'sponsored')
    create(:billable_item, site: site, item: @flat_design, state: 'suspended')
    create(:billable_item, site: site, item: @logo_addon_plan_1, state: 'subscribed')
    create(:billable_item, site: site, item: @stats_addon_plan_1, state: 'sponsored')
    create(:billable_item, site: site, item: @support_addon_plan_1, state: 'suspended')
  end

  describe '#app_design_is_active?' do
    it 'returns true when the addon is beta, trial, sponsored or paying, false otherwise' do
      site.app_design_is_active?(@classic_design).should be_true
      site.app_design_is_active?(@light_design).should be_true
      site.app_design_is_active?(@flat_design).should be_false
    end
  end

  describe '#addon_plan_is_active?' do
    it 'returns true when the addon is beta, trial, sponsored or paying, false otherwise' do
      site.addon_plan_is_active?(@logo_addon_plan_1).should be_true
      site.addon_plan_is_active?(@stats_addon_plan_1).should be_true
      site.addon_plan_is_active?(@support_addon_plan_1).should be_false
    end
  end

  pending '#addon_is_active?' do
    it 'returns true when the addon is beta, trial, sponsored or subscribed, false otherwise' do
      site.addon_is_active?('logo').should be_true
      site.addon_is_active?('foo').should be_true
      site.addon_is_active?('stats').should be_true
      site.addon_is_active?('bar').should be_true

      site.addon_is_active?('baz').should be_false
      site.addon_is_active?('fooz').should be_false
    end
  end

  describe '#out_of_trial?' do
    before do
      create(:billable_item_activity, site: site, item: @logo_addon_plan_2, state: 'trial', created_at: 29.days.ago)
      create(:billable_item_activity, site: site, item: @logo_addon_plan_3, state: 'trial', created_at: 30.days.ago)
      create(:billable_item_activity, site: site, item: @stats_addon_plan_2, state: 'trial', created_at: 31.days.ago)
      create(:billable_item_activity, site: site, item: @stats_addon_plan_3, state: 'subscribed', created_at: 31.days.ago)
    end

    it { site.out_of_trial?(@logo_addon_plan_2).should be_false }
    it { site.out_of_trial?(@logo_addon_plan_3).should be_true }
    it { site.out_of_trial?(@stats_addon_plan_2).should be_true }
    it { site.out_of_trial?(@stats_addon_plan_3).should be_false }
  end

end