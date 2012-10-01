require "spec_helper"

describe SiteModules::Addon, :addons do
  let(:site)   { create(:site) }
  let(:addon1) { create(:addon, category: 'foo') }
  let(:addon2) { create(:addon, category: 'bar') }
  let(:addon3) { create(:addon, category: 'baz') }
  let(:addon4) { create(:addon, category: 'fooz') }
  before do
    create(:addonship, site: site, addon: addon1, state: 'beta')
    create(:addonship, site: site, addon: @logo_no_logo_addon, state: 'trial')
    create(:addonship, site: site, addon: @stats_standard_addon, state: 'sponsored')
    create(:addonship, site: site, addon: addon2, state: 'subscribed')

    create(:addonship, site: site, addon: addon3, state: 'inactive')
    create(:addonship, site: site, addon: addon4, state: 'suspended')
  end

  describe '#addon_is_active?' do
    it 'returns true when the addon is beta, trial, sponsored or paying, false otherwise' do
      site.addon_is_active?(addon1).should be_true
      site.addon_is_active?(@logo_no_logo_addon).should be_true
      site.addon_is_active?(@stats_standard_addon).should be_true
      site.addon_is_active?(addon2).should be_true
      site.addon_is_active?(@support_vip_addon).should be_false
      site.addon_is_active?(addon3).should be_false
    end
  end

  describe '#active_addon_in_category?' do
    it 'returns true when the addon is beta, trial, sponsored or subscribed, false otherwise' do
      site.active_addon_in_category?('logo').should be_true
      site.active_addon_in_category?('foo').should be_true
      site.active_addon_in_category?('stats').should be_true
      site.active_addon_in_category?('bar').should be_true

      site.active_addon_in_category?('baz').should be_false
      site.active_addon_in_category?('fooz').should be_false
    end
  end

end
