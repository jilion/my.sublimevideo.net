require 'spec_helper'

require 'sites_tasks'

describe SitesTasks do

  describe '.regenerate_templates' do
    let!(:site) { create(:site) }
    let!(:archived_site) { create(:site, state: 'archived') }

    it 'regenerates loader and license of all sites' do
      expect(LoaderGenerator).to delay(:update_all_stages!).with(site.id)
      described_class.regenerate_templates(loaders: true)
      expect(SettingsGenerator).to delay(:update_all!).with(site.id)

      described_class.regenerate_templates(settings: true)
    end
  end

  describe '.subscribe_all_sites_to_free_addon' do
    let!(:site1) { create(:site) }
    let!(:site2) { create(:site) }
    let!(:archived_site) { create(:site, state: 'archived') }
    let!(:beta_addon_plan) { create(:addon_plan, required_stage: 'beta') }
    before do
      create(:billable_item, site: site1, item: beta_addon_plan, state: 'beta')
    end

    it 'delays subscribing to the embed add-on for all sites not subscribed yet' do
      expect(SiteManager).to delay(:subscribe_site_to_addon).with(site2.id, beta_addon_plan.addon_name, beta_addon_plan.id)

      described_class.subscribe_all_sites_to_free_addon(beta_addon_plan.addon_name, beta_addon_plan.name)
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

      allow(LoaderGenerator).to receive(:update_all_stages!)
      allow(SettingsGenerator).to receive(:update_all!)
    end

    it 'do many things' do
      expect(design.stable_at).to be_nil
      expect(custom_design.stable_at).to be_nil
      expect(addon_plan_1.stable_at).to be_nil
      expect(addon_plan_2.stable_at).to be_nil
      expect(addon_plan_3.stable_at).to be_nil

      expect(design.required_stage).to eq 'beta'
      expect(custom_design.required_stage).to eq 'beta'
      expect(addon_plan_1.required_stage).to eq 'beta'
      expect(addon_plan_2.required_stage).to eq 'beta'
      expect(addon_plan_3.required_stage).to eq 'beta'

      expect(site1.billable_items.with_item(addon_plan_1).state('beta').size).to eq(1)
      expect(site2.billable_items.with_item(addon_plan_2).state('beta').size).to eq(1)
      expect(site3.billable_items.with_item(addon_plan_1).state('beta').size).to eq(1)
      expect(site4.billable_items.with_item(addon_plan_2).state('beta').size).to eq(1)

      expect(site1.billable_items.with_item(design).state('beta').size).to eq(1)
      expect(site2.billable_items.with_item(design).state('beta').size).to eq(1)
      expect(site3.billable_items.with_item(design).state('beta').size).to eq(0)
      expect(site4.billable_items.with_item(design).state('beta').size).to eq(0)

      expect(site1.billable_items.with_item(custom_design).state('beta').size).to eq(1)
      expect(site2.billable_items.with_item(custom_design).size).to eq(0)
      expect(site3.billable_items.with_item(custom_design).size).to eq(0)
      expect(site4.billable_items.with_item(custom_design).size).to eq(0)

      Sidekiq::Worker.clear_all
      described_class.exit_beta
      Sidekiq::Worker.drain_all

      # it moves beta addon plans out of beta
      expect(design.reload.stable_at).to be_present
      expect(custom_design.reload.stable_at).to be_present
      expect(addon_plan_2.reload.stable_at).to be_present
      expect(addon_plan_1.reload.stable_at).to be_present
      expect(addon_plan_3.reload.stable_at).to be_present

      expect(design.reload.required_stage).to eq 'stable'
      expect(custom_design.reload.required_stage).to eq 'stable'
      expect(addon_plan_2.reload.required_stage).to eq 'stable'
      expect(addon_plan_1.reload.required_stage).to eq 'stable'
      expect(addon_plan_3.reload.required_stage).to eq 'stable'

      expect(site1.reload.billable_items.with_item(design).state('subscribed').size).to eq(1)
      expect(site2.reload.billable_items.with_item(design).state('subscribed').size).to eq(1)
      expect(site3.reload.billable_items.with_item(design).state('subscribed').size).to eq(0)
      expect(site4.reload.billable_items.with_item(design).state('subscribed').size).to eq(0)

      # updates free add-ons subscriptions to the "subscribed" state
      expect(site1.billable_items.with_item(addon_plan_3).state('subscribed').size).to eq(1)
      expect(site2.billable_items.with_item(addon_plan_3).state('subscribed').size).to eq(1)
      expect(site3.billable_items.with_item(addon_plan_3).state('subscribed').size).to eq(0)
      expect(site4.billable_items.with_item(addon_plan_3).state('subscribed').size).to eq(0)

      # updates subscriptions to the "trial" state for beta subscriptions subscribed less than 30 days ago
      expect(site1.billable_items.with_item(addon_plan_1).state('trial').size).to eq(1)
      expect(site2.billable_items.with_item(addon_plan_2).state('trial').size).to eq(1)
      expect(site3.billable_items.with_item(addon_plan_1).state('trial').size).to eq(1)
      expect(site4.billable_items.with_item(addon_plan_2).state('trial').size).to eq(1)

      # updates subscriptions to free plan (or cancel plan) for beta subscriptions subscribed more than 30 days ago when user has no credit card
      expect(site1.billable_items.with_item(addon_plan_2).size).to eq(0)
      expect(site1.billable_items.with_item(addon_plan_2_free).state('subscribed').size).to eq(1)
      expect(site2.billable_items.with_item(addon_plan_1).size).to eq(0)

      # updates subscriptions to the "subscribed" state for beta subscriptions subscribed more than 30 days ago when user has a credit card
      expect(site3.billable_items.with_item(addon_plan_2).state('subscribed').size).to eq(1)
      expect(site4.billable_items.with_item(addon_plan_1).state('subscribed').size).to eq(1)

      # does not subscribe site to custom add-ons for which it was not subscribed before
      expect(site1.billable_items.with_item(custom_design).state('subscribed').size).to eq(1)
      expect(site2.billable_items.with_item(custom_design).size).to eq(0)
      expect(site3.billable_items.with_item(custom_design).size).to eq(0)
      expect(site4.billable_items.with_item(custom_design).size).to eq(0)
    end
  end

end
