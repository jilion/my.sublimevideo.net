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

  describe '.subscribe_all_sites_to_best_addon_plans', :addons do
    let!(:site1) { SiteManager.new(build(:site)).tap { |sm| sm.create }.site }
    let!(:site2) { SiteManager.new(build(:site)).tap { |sm| sm.create }.site }
    let!(:archived_site) { create(:site, state: 'archived') }
    before do
      @subscriptions = {}
      @subscriptions[:logo] = AddonPlan.get('logo', 'custom').id
      @subscriptions[:social_sharing] = AddonPlan.get('social_sharing', 'standard').id
      @subscriptions[:embed] = AddonPlan.get('embed', 'auto').id
      @subscriptions[:cuezones] = AddonPlan.get('cuezones', 'standard').id
      @subscriptions[:google_analytics] = AddonPlan.get('google_analytics', 'standard').id
      @subscriptions[:support] = AddonPlan.get('support', 'standard').id # downgrade everyone to no support

      SiteManager.update_billable_items(site1.id, {}, {
        logo: AddonPlan.get('logo', 'disabled').id,
        social_sharing: '0',
        embed: AddonPlan.get('embed', 'manual').id,
        cuezones: '0',
        google_analytics: '0',
        support: AddonPlan.get('support', 'vip').id
      }, force: 'sponsored')

      SiteManager.update_billable_items(site2.id, {}, {
        logo: AddonPlan.get('logo', 'disabled').id,
        social_sharing: '0',
        embed: AddonPlan.get('embed', 'manual').id,
        cuezones: '0',
        google_analytics: '0',
        support: AddonPlan.get('support', 'vip').id,
        stats: AddonPlan.get('stats', 'realtime').id
      })

      Sidekiq::Worker.clear_all
    end

    it 'delays subscribing to all best add-ons except the stats and support add-ons' do
      expect(site1.billable_items.with_item(AddonPlan.get('logo', 'disabled')).state('sponsored').size).to eq 1
      expect(site1.billable_items.with_item(AddonPlan.get('social_sharing', 'standard')).size).to eq 0
      expect(site1.billable_items.with_item(AddonPlan.get('embed', 'manual')).state('subscribed').size).to eq 1
      expect(site1.billable_items.with_item(AddonPlan.get('cuezones', 'standard')).size).to eq 0
      expect(site1.billable_items.with_item(AddonPlan.get('google_analytics', 'standard')).size).to eq 0
      expect(site1.billable_items.with_item(AddonPlan.get('support', 'vip')).state('sponsored').size).to eq 1

      expect(site2.billable_items.with_item(AddonPlan.get('logo', 'disabled')).state('trial').size).to eq 1
      expect(site2.billable_items.with_item(AddonPlan.get('social_sharing', 'standard')).size).to eq 0
      expect(site2.billable_items.with_item(AddonPlan.get('embed', 'manual')).state('subscribed').size).to eq 1
      expect(site2.billable_items.with_item(AddonPlan.get('cuezones', 'standard')).size).to eq 0
      expect(site2.billable_items.with_item(AddonPlan.get('google_analytics', 'standard')).size).to eq 0
      expect(site2.billable_items.with_item(AddonPlan.get('support', 'vip')).state('trial').size).to eq 1
      expect(site2.billable_items.with_item(AddonPlan.get('stats', 'realtime')).state('trial').size).to eq 1

      described_class.subscribe_all_sites_to_best_addon_plans

      Sidekiq::Worker.drain_all

      expect(site1.billable_items.with_item(AddonPlan.get('logo', 'custom')).state('sponsored').size).to eq 1
      expect(site1.billable_items.with_item(AddonPlan.get('social_sharing', 'standard')).state('sponsored').size).to eq 1
      expect(site1.billable_items.with_item(AddonPlan.get('embed', 'auto')).state('sponsored').size).to eq 1
      expect(site1.billable_items.with_item(AddonPlan.get('cuezones', 'standard')).state('sponsored').size).to eq 1
      expect(site1.billable_items.with_item(AddonPlan.get('google_analytics', 'standard')).state('sponsored').size).to eq 1
      expect(site1.billable_items.with_item(AddonPlan.get('support', 'standard')).state('subscribed').size).to eq 1

      expect(site2.billable_items.with_item(AddonPlan.get('logo', 'custom')).state('sponsored').size).to eq 1
      expect(site2.billable_items.with_item(AddonPlan.get('social_sharing', 'standard')).state('sponsored').size).to eq 1
      expect(site2.billable_items.with_item(AddonPlan.get('embed', 'auto')).state('sponsored').size).to eq 1
      expect(site2.billable_items.with_item(AddonPlan.get('cuezones', 'standard')).state('sponsored').size).to eq 1
      expect(site2.billable_items.with_item(AddonPlan.get('google_analytics', 'standard')).state('sponsored').size).to eq 1
      expect(site2.billable_items.with_item(AddonPlan.get('support', 'standard')).state('subscribed').size).to eq 1
      expect(site2.billable_items.with_item(AddonPlan.get('stats', 'realtime')).state('sponsored').size).to eq 1
    end
  end

end
