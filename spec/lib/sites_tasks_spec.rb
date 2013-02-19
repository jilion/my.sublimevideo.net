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
      SiteManager.should delay(:subscribe_site_to_addon).with(site2.id, 'embed', @embed_addon_plan_1.id)

      described_class.subscribe_all_sites_to_free_addon('embed', 'standard')
    end
  end

  describe '.exit_beta', :addons do
    let!(:user1) { create(:user_no_cc) }
    let!(:user2) { create(:user_no_cc) }
    let!(:user3) { create(:user) }
    let!(:user4) { create(:user) }
    let!(:site1) { SiteManager.new(build(:site, user: user1)).tap { |s| s.create }.site }
    let!(:site2) { SiteManager.new(build(:site, user: user2)).tap { |s| s.create }.site }
    let!(:site3) { SiteManager.new(build(:site, user: user3)).tap { |s| s.create }.site }
    let!(:site4) { SiteManager.new(build(:site, user: user4)).tap { |s| s.create }.site }
    before do
      create(:billable_item_activity, site: site1, item: @html5_design, state: 'beta', created_at: 31.days.ago) # free & custom
      create(:billable_item, site: site1, item: @html5_design, state: 'beta') # free & custom

      create(:billable_item_activity, site: site1, item: @social_sharing_addon_plan_1, state: 'beta', created_at: 20.days.ago) # in trial
      create(:billable_item, site: site1, item: @social_sharing_addon_plan_1, state: 'beta') # in trial

      create(:billable_item_activity, site: site1, item: @logo_addon_plan_3, state: 'beta', created_at: 31.days.ago) # out of trial
      create(:billable_item, site: site1, item: @logo_addon_plan_3, state: 'beta') # out of trial


      create(:billable_item_activity, site: site2, item: @social_sharing_addon_plan_1, state: 'beta', created_at: 31.days.ago) #  out of trial
      create(:billable_item, site: site2, item: @social_sharing_addon_plan_1, state: 'beta') #  out of trial

      create(:billable_item_activity, site: site2, item: @logo_addon_plan_3, state: 'beta', created_at: 20.days.ago) # in trial
      create(:billable_item, site: site2, item: @logo_addon_plan_3, state: 'beta') # in trial

      site2.billable_item_activities.addon_plans.where(item_id: @embed_addon_plan_1).first.destroy
      create(:billable_item_activity, site: site2, item: @embed_addon_plan_1, state: 'beta', created_at: 31.days.ago) # free


      create(:billable_item_activity, site: site3, item: @social_sharing_addon_plan_1, state: 'beta', created_at: 20.days.ago) # in trial
      create(:billable_item, site: site3, item: @social_sharing_addon_plan_1, state: 'beta') # in trial

      create(:billable_item_activity, site: site3, item: @logo_addon_plan_3, state: 'beta', created_at: 31.days.ago) # out of trial
      create(:billable_item, site: site3, item: @logo_addon_plan_3, state: 'beta')


      create(:billable_item_activity, site: site4, item: @social_sharing_addon_plan_1, state: 'beta', created_at: 31.days.ago) #  out of trial
      create(:billable_item, site: site4, item: @social_sharing_addon_plan_1, state: 'beta') #  out of trial

      create(:billable_item_activity, site: site4, item: @logo_addon_plan_3, state: 'beta', created_at: 20.days.ago) # in trial
      create(:billable_item, site: site4, item: @logo_addon_plan_3, state: 'beta') # in trial

      site4.billable_item_activities.addon_plans.where(item_id: @embed_addon_plan_1).first.destroy
      create(:billable_item_activity, site: site4, item: @embed_addon_plan_1, state: 'beta', created_at: 31.days.ago) # free
    end

    it 'do many things' do
      @flat_design.stable_at.should be_nil
      @html5_design.stable_at.should be_nil
      @logo_addon_plan_3.stable_at.should be_nil
      @social_sharing_addon_plan_1.stable_at.should be_nil
      @embed_addon_plan_1.stable_at.should be_nil

      @flat_design.required_stage.should eq 'beta'
      @html5_design.required_stage.should eq 'beta'
      @logo_addon_plan_3.required_stage.should eq 'beta'
      @social_sharing_addon_plan_1.required_stage.should eq 'beta'
      @embed_addon_plan_1.required_stage.should eq 'beta'

      site1.billable_items.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'beta').should have(1).item
      site2.billable_items.addon_plans.where(item_id: @logo_addon_plan_3).where(state: 'beta').should have(1).item
      site3.billable_items.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'beta').should have(1).item
      site4.billable_items.addon_plans.where(item_id: @logo_addon_plan_3).where(state: 'beta').should have(1).item

      site1.billable_items.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'beta').should have(1).item
      site2.billable_items.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'beta').should have(1).item

      site1.billable_items.app_designs.where(item_id: @html5_design).where(state: 'beta').should have(1).item
      site2.billable_items.app_designs.where(item_id: @html5_design).should be_empty

      Sidekiq::Worker.clear_all
      described_class.exit_beta
      Sidekiq::Worker.drain_all

      puts 'it moves beta addon plans out of beta'
      @flat_design.reload.stable_at.should be_present
      @html5_design.reload.stable_at.should be_present
      @logo_addon_plan_3.reload.stable_at.should be_present
      @social_sharing_addon_plan_1.reload.stable_at.should be_present
      @embed_addon_plan_1.reload.stable_at.should be_present

      @flat_design.reload.required_stage.should eq 'stable'
      @html5_design.reload.required_stage.should eq 'stable'
      @logo_addon_plan_3.reload.required_stage.should eq 'stable'
      @social_sharing_addon_plan_1.reload.required_stage.should eq 'stable'
      @embed_addon_plan_1.reload.required_stage.should eq 'stable'

      puts 'updates free designs subscriptions to the "subscribed" state'
      site1.reload.billable_items.app_designs.where(item_id: @flat_design).where(state: 'subscribed').should have(1).item
      site2.reload.billable_items.app_designs.where(item_id: @flat_design).where(state: 'subscribed').should have(1).item
      site3.reload.billable_items.app_designs.where(item_id: @flat_design).where(state: 'subscribed').should have(1).item
      site4.reload.billable_items.app_designs.where(item_id: @flat_design).where(state: 'subscribed').should have(1).item

      puts 'updates free add-ons subscriptions to the "subscribed" state'
      site1.billable_items.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'subscribed').should have(1).item
      site2.billable_items.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'subscribed').should have(1).item
      site3.billable_items.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'subscribed').should have(1).item
      site4.billable_items.addon_plans.where(item_id: @embed_addon_plan_1).where(state: 'subscribed').should have(1).item

      puts 'updates subscriptions to the "trial" state for beta subscriptions subscribed less than 30 days ago'
      site1.billable_items.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'trial').should have(1).item
      site2.billable_items.addon_plans.where(item_id: @logo_addon_plan_3).where(state: 'trial').should have(1).item
      site3.billable_items.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'trial').should have(1).item
      site4.billable_items.addon_plans.where(item_id: @logo_addon_plan_3).where(state: 'trial').should have(1).item

      puts 'updates subscriptions to free plan (or cancel plan) for beta subscriptions subscribed more than 30 days ago when user has no credit card'
      site1.billable_items.addon_plans.where(item_id: @logo_addon_plan_3).should be_empty
      site1.billable_items.addon_plans.where(item_id: @logo_addon_plan_1).where(state: 'subscribed').should have(1).item
      site2.billable_items.addon_plans.where(item_id: @social_sharing_addon_plan_1).should be_empty

      puts 'updates subscriptions to the "subscribed" state for beta subscriptions subscribed more than 30 days ago when user has a credit card'
      site3.billable_items.addon_plans.where(item_id: @logo_addon_plan_3).where(state: 'subscribed').should have(1).item
      site4.billable_items.addon_plans.where(item_id: @social_sharing_addon_plan_1).where(state: 'subscribed').should have(1).item

      puts 'does not subscribe site to custom add-ons for which it was not subscribed before'
      site1.billable_items.app_designs.where(item_id: @html5_design).where(state: 'subscribed').should have(1).item
      site2.billable_items.app_designs.where(item_id: @html5_design).should be_empty
      site3.billable_items.app_designs.where(item_id: @html5_design).should be_empty
      site4.billable_items.app_designs.where(item_id: @html5_design).should be_empty
    end
  end

end
