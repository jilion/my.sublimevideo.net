require 'spec_helper'

describe SiteModules::BillableItem, :addons do
  let(:site) { create(:site) }
  before do
    create(:billable_item, site: site, item: @classic_design, state: 'subscribed')
    create(:billable_item, site: site, item: @light_design, state: 'sponsored')
    create(:billable_item, site: site, item: @flat_design, state: 'suspended')
    create(:billable_item, site: site, item: @logo_addon_plan_2, state: 'subscribed')
    create(:billable_item, site: site, item: @stats_addon_plan_2, state: 'sponsored')
    create(:billable_item, site: site, item: @support_addon_plan_2, state: 'suspended')
  end

  describe '#subscribed_to?' do
    it 'returns true when the item is beta, trial, sponsored or paying, false otherwise' do
      site.subscribed_to?(@logo_addon_plan_2).should be_true
      site.subscribed_to?(@stats_addon_plan_2).should be_true
      site.subscribed_to?(@support_addon_plan_2).should be_false
      site.subscribed_to?(@classic_design).should be_true
      site.subscribed_to?(@light_design).should be_true
      site.subscribed_to?(@flat_design).should be_false
    end
  end

  describe '#sponsored_to?' do
    it 'returns true when the item is beta, trial, sponsored or paying, false otherwise' do
      site.sponsored_to?(@logo_addon_plan_2).should be_false
      site.sponsored_to?(@stats_addon_plan_2).should be_true
      site.sponsored_to?(@support_addon_plan_2).should be_false
      site.sponsored_to?(@classic_design).should be_false
      site.sponsored_to?(@light_design).should be_true
      site.sponsored_to?(@flat_design).should be_false
    end
  end

  describe '#addon_plan_for_addon_name' do
    it 'returns the addon plan currently used for the given addon id' do
      site.addon_plan_for_addon_name(@logo_addon.name).should eq @logo_addon_plan_2
      site.addon_plan_for_addon_name(@stats_addon.name).should eq @stats_addon_plan_2
    end
  end

  describe '#total_billable_items_price' do
    before do
      @addon_plan = create(:addon_plan, price: 1990)
      create(:billable_item, site: site, item: @addon_plan, state: 'trial')
    end

    it { site.total_billable_items_price.should eq @classic_design.price + @logo_addon_plan_2.price + @addon_plan.price }
  end

end
