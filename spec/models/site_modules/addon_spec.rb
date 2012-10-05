require "spec_helper"

describe SiteModules::Addon, :addons do
  let(:site) { create(:site) }
  before do
    @billable_item2 = create(:billable_item, site: site, item: @logo_addon_plan_1, state: 'subscribed')
    @billable_item3 = create(:billable_item, site: site, item: @stats_addon_plan_1, state: 'sponsored')
    @billable_item4 = create(:billable_item, site: site, item: @support_addon_plan_1, state: 'suspended')
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

end
