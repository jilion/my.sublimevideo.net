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
        support: AddonPlan.get('support', 'vip').id
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
    end
  end

  describe '.exit_beta' do
    let!(:user1) { create(:user_no_cc) }
    let!(:user2) { create(:user_no_cc) }
    let!(:user3) { create(:user) }
    let!(:user4) { create(:user) }
    let!(:site1) { create(:site, user: user1) }
    let!(:site2) { create(:site, user: user2) }
    let!(:site3) { create(:site, user: user3) }
    let!(:site4) { create(:site, user: user4) }
    let!(:design) { create(:design, required_stage: 'beta', stable_at: nil, price: 0) }
    let!(:custom_design) { create(:design, availability: 'custom', required_stage: 'beta', stable_at: nil, price: 0) }
    let!(:addon_plan_1) { create(:addon_plan, required_stage: 'beta', stable_at: nil) }
    let!(:addon_plan_2) { create(:addon_plan, required_stage: 'beta', stable_at: nil) }
    let!(:addon_plan_2_free) { create(:addon_plan, addon: addon_plan_2.addon, required_stage: 'beta', stable_at: nil, price: 0) }
    let!(:addon_plan_3) { create(:addon_plan, required_stage: 'beta', stable_at: nil, price: 0) }

    before do
      create(:billable_item_activity, site: site1, item: design, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) # free
      create(:billable_item, site: site1, item: design, state: 'beta') # free

      create(:billable_item_activity, site: site1, item: custom_design, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) # free & custom
      create(:billable_item, site: site1, item: custom_design, state: 'beta') # free & custom

      create(:billable_item_activity, site: site1, item: addon_plan_1, state: 'beta', created_at: (BusinessModel.days_for_trial / 2).days.ago) # in trial
      create(:billable_item, site: site1, item: addon_plan_1, state: 'beta') # in trial

      create(:billable_item_activity, site: site1, item: addon_plan_2, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) # out of trial
      create(:billable_item, site: site1, item: addon_plan_2, state: 'beta') # out of trial

      create(:billable_item_activity, site: site1, item: addon_plan_3, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) # free
      create(:billable_item, site: site1, item: addon_plan_3, state: 'beta') # free


      create(:billable_item_activity, site: site2, item: design, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) # free
      create(:billable_item, site: site2, item: design, state: 'beta') # free

      create(:billable_item_activity, site: site2, item: addon_plan_1, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) # out of trial
      create(:billable_item, site: site2, item: addon_plan_1, state: 'beta') # out of trial

      create(:billable_item_activity, site: site2, item: addon_plan_2, state: 'beta', created_at: (BusinessModel.days_for_trial / 2).days.ago) # in trial
      create(:billable_item, site: site2, item: addon_plan_2, state: 'beta') # in trial

      create(:billable_item_activity, site: site2, item: addon_plan_3, state: 'beta', created_at: (BusinessModel.days_for_trial / 2).days.ago) # free
      create(:billable_item, site: site2, item: addon_plan_3, state: 'beta') # free


      create(:billable_item_activity, site: site3, item: addon_plan_1, state: 'beta', created_at: (BusinessModel.days_for_trial / 2).days.ago) # in trial
      create(:billable_item, site: site3, item: addon_plan_1, state: 'beta') # in trial

      create(:billable_item_activity, site: site3, item: addon_plan_2, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) # out of trial
      create(:billable_item, site: site3, item: addon_plan_2, state: 'beta')


      create(:billable_item_activity, site: site4, item: addon_plan_1, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) # out of trial
      create(:billable_item, site: site4, item: addon_plan_1, state: 'beta') # out of trial

      create(:billable_item_activity, site: site4, item: addon_plan_2, state: 'beta', created_at: (BusinessModel.days_for_trial / 2).days.ago) # in trial
      create(:billable_item, site: site4, item: addon_plan_2, state: 'beta') # in trial

      LoaderGenerator.stub(:update_all_stages!)
      SettingsGenerator.stub(:update_all!)
    end

    it 'do many things' do
      design.stable_at.should be_nil
      custom_design.stable_at.should be_nil
      addon_plan_1.stable_at.should be_nil
      addon_plan_2.stable_at.should be_nil
      addon_plan_3.stable_at.should be_nil

      design.required_stage.should eq 'beta'
      custom_design.required_stage.should eq 'beta'
      addon_plan_1.required_stage.should eq 'beta'
      addon_plan_2.required_stage.should eq 'beta'
      addon_plan_3.required_stage.should eq 'beta'

      site1.billable_items.with_item(addon_plan_1).state('beta').should have(1).item
      site2.billable_items.with_item(addon_plan_2).state('beta').should have(1).item
      site3.billable_items.with_item(addon_plan_1).state('beta').should have(1).item
      site4.billable_items.with_item(addon_plan_2).state('beta').should have(1).item

      site1.billable_items.with_item(design).state('beta').should have(1).item
      site2.billable_items.with_item(design).state('beta').should have(1).item
      site3.billable_items.with_item(design).state('beta').should be_empty
      site4.billable_items.with_item(design).state('beta').should be_empty

      site1.billable_items.with_item(custom_design).state('beta').should have(1).item
      site2.billable_items.with_item(custom_design).should be_empty
      site3.billable_items.with_item(custom_design).should be_empty
      site4.billable_items.with_item(custom_design).should be_empty

      Sidekiq::Worker.clear_all
      described_class.exit_beta
      Sidekiq::Worker.drain_all

      # it moves beta addon plans out of beta
      design.reload.stable_at.should be_present
      custom_design.reload.stable_at.should be_present
      addon_plan_2.reload.stable_at.should be_present
      addon_plan_1.reload.stable_at.should be_present
      addon_plan_3.reload.stable_at.should be_present

      design.reload.required_stage.should eq 'stable'
      custom_design.reload.required_stage.should eq 'stable'
      addon_plan_2.reload.required_stage.should eq 'stable'
      addon_plan_1.reload.required_stage.should eq 'stable'
      addon_plan_3.reload.required_stage.should eq 'stable'

      site1.reload.billable_items.with_item(design).state('subscribed').should have(1).item
      site2.reload.billable_items.with_item(design).state('subscribed').should have(1).item
      site3.reload.billable_items.with_item(design).state('subscribed').should be_empty
      site4.reload.billable_items.with_item(design).state('subscribed').should be_empty

      # updates free add-ons subscriptions to the "subscribed" state
      site1.billable_items.with_item(addon_plan_3).state('subscribed').should have(1).item
      site2.billable_items.with_item(addon_plan_3).state('subscribed').should have(1).item
      site3.billable_items.with_item(addon_plan_3).state('subscribed').should be_empty
      site4.billable_items.with_item(addon_plan_3).state('subscribed').should be_empty

      # updates subscriptions to the "trial" state for beta subscriptions subscribed less than 30 days ago
      site1.billable_items.with_item(addon_plan_1).state('trial').should have(1).item
      site2.billable_items.with_item(addon_plan_2).state('trial').should have(1).item
      site3.billable_items.with_item(addon_plan_1).state('trial').should have(1).item
      site4.billable_items.with_item(addon_plan_2).state('trial').should have(1).item

      # updates subscriptions to free plan (or cancel plan) for beta subscriptions subscribed more than 30 days ago when user has no credit card
      site1.billable_items.with_item(addon_plan_2).should be_empty
      site1.billable_items.with_item(addon_plan_2_free).state('subscribed').should have(1).item
      site2.billable_items.with_item(addon_plan_1).should be_empty

      # updates subscriptions to the "subscribed" state for beta subscriptions subscribed more than 30 days ago when user has a credit card
      site3.billable_items.with_item(addon_plan_2).state('subscribed').should have(1).item
      site4.billable_items.with_item(addon_plan_1).state('subscribed').should have(1).item

      # does not subscribe site to custom add-ons for which it was not subscribed before
      site1.billable_items.with_item(custom_design).state('subscribed').should have(1).item
      site2.billable_items.with_item(custom_design).should be_empty
      site3.billable_items.with_item(custom_design).should be_empty
      site4.billable_items.with_item(custom_design).should be_empty
    end
  end

end
