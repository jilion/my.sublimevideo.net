# coding: utf-8
require 'spec_helper'
require 'one_time/site'

describe OneTime::Site do

  describe '.regenerate_templates' do
    let!(:site) { create(:site) }
    let!(:archived_site) { create(:site, state: 'archived') }

    it 'regenerates loader and license of all sites' do
      Service::Loader.should delay(:update_all_stages!).with(site.id)
      described_class.regenerate_templates(loaders: true)
      Service::Settings.should delay(:update_all_types!).with(site.id)

      described_class.regenerate_templates(settings: true)
    end
  end

  describe '.subscribe_all_sites_to_embed_addon', :addons do
    let!(:site1) { create(:site) }
    let!(:site2) { create(:site) }
    let!(:archived_site) { create(:site, state: 'archived') }
    before do
      create(:billable_item, site: site1, item: @embed_addon_plan_1, state: 'beta')
    end

    it 'delays subscribing to the embed add-on for all sites not subscribed yet' do
      OneTime::Site.should delay(:subscribe_site_to_embed_addon).with(site2.id, @embed_addon_plan_1.id)

      described_class.subscribe_all_sites_to_embed_addon
    end
  end

  describe '.subscribe_site_to_embed_addon', :addons do
    let!(:site) { create(:site) }

    it 'delays subscribing to the embed add-on for all sites not subscribed yet' do
      Service::Site.should_receive(:new).with(site) do |service|
        service.should_receive(:update_billable_items).with({}, { 'embed' => @embed_addon_plan_1.id })
        service
      end

      described_class.subscribe_site_to_embed_addon(site.id, @embed_addon_plan_1.id)
    end
  end

end
