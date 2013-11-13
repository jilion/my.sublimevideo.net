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
      expect(site.subscribed_to?(@logo_addon_plan_2)).to be_truthy
      expect(site.subscribed_to?(@stats_addon_plan_2)).to be_truthy
      expect(site.subscribed_to?(@support_addon_plan_2)).to be_falsey
      expect(site.subscribed_to?(@classic_design)).to be_truthy
      expect(site.subscribed_to?(@light_design)).to be_truthy
      expect(site.subscribed_to?(@flat_design)).to be_falsey
    end
  end

  describe '#sponsored_to?' do
    it 'returns true when the item is beta, trial, sponsored or paying, false otherwise' do
      expect(site.sponsored_to?(@logo_addon_plan_2)).to be_falsey
      expect(site.sponsored_to?(@stats_addon_plan_2)).to be_truthy
      expect(site.sponsored_to?(@support_addon_plan_2)).to be_falsey
      expect(site.sponsored_to?(@classic_design)).to be_falsey
      expect(site.sponsored_to?(@light_design)).to be_truthy
      expect(site.sponsored_to?(@flat_design)).to be_falsey
    end
  end

  describe '#addon_plan_for_addon_name' do
    it 'returns the addon plan currently used for the given addon id' do
      expect(site.addon_plan_for_addon_name(@logo_addon.name)).to eq @logo_addon_plan_2
      expect(site.addon_plan_for_addon_name(@stats_addon.name)).to eq @stats_addon_plan_2
    end
  end

  describe '#total_billable_items_price' do
    before do
      @addon_plan = create(:addon_plan, price: 1990)
      create(:billable_item, site: site, item: @addon_plan, state: 'trial')
    end

    it { expect(site.total_billable_items_price).to eq @classic_design.price + @logo_addon_plan_2.price + @addon_plan.price }
  end

end
