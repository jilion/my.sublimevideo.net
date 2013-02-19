require 'spec_helper'

require 'sites_tasks'

describe SitesTasks do

  describe '.regenerate_templates' do
    let!(:site) { create(:site) }
    let!(:archived_site) { create(:site, state: 'archived') }

    it 'regenerates loader and license of all sites' do
      LoaderGenerator.should delay(:update_all_stages!).with(site.id)
      described_class.regenerate_templates(loaders: true)
      SettingsGenerator.should delay(:update_all!).with(site.id)

      described_class.regenerate_templates(settings: true)
    end
  end

  describe '.subscribe_all_sites_to_free_addon', :addons do
    let!(:site1) { create(:site) }
    let!(:site2) { create(:site) }
    let!(:archived_site) { create(:site, state: 'archived') }
    before do
      create(:billable_item, site: site1, item: @embed_addon_plan_1, state: 'beta')
    end

    it 'delays subscribing to the embed add-on for all sites not subscribed yet' do
      SiteManager.should delay(:subscribe_site_to_free_addon).with(site2.id, @embed_addon_plan_1.id)

      described_class.subscribe_all_sites_to_free_addon('embed', 'standard')
    end
  end

end
