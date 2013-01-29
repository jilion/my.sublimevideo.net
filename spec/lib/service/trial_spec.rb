require 'spec_helper'

describe Service::Trial do
  let(:user)             { create(:user) }
  let(:site0)            { create(:site, user: user) }
  let(:site1)            { create(:site, user: user) }
  let(:site2)            { create(:site, user: user) }
  let(:site3)            { create(:site, user: user) }
  let(:archived_site)    { create(:site, user: user, state: 'archived') }
  let(:app_design_paid1) { create(:app_design, price: 995) }
  let(:app_design_paid2) { create(:app_design, price: 995) }
  let(:addon)            { create(:addon) }
  let(:addon2)           { create(:addon) }
  let(:addon_plan_paid1) { create(:addon_plan, addon: addon, price: 995) }
  let(:addon_plan_paid2) { create(:addon_plan, addon: addon2, price: 1995) }
  let(:service) { stub }
  before do
    @free_addon_plan = create(:addon_plan, addon: addon, price: 0)
  end

  describe '.send_trial_will_expire_email' do
    before do
      @billable_items_wont_receive_email = [create(:billable_item, site: site0, item: create(:addon_plan), state: 'trial')]
      @billable_items_will_receive_email = []

      BusinessModel.days_before_trial_end.each do |days_before_trial_end|
        Timecop.travel((BusinessModel.days_for_trial - days_before_trial_end + 1).days.ago) do
          @billable_items_wont_receive_email << create(:billable_item, site: site0, item: create(:addon_plan), state: 'subscribed')
          @billable_items_will_receive_email << create(:billable_item, site: site0, item: create(:addon_plan), state: 'trial')
        end
      end
    end

    it 'delays .activate_billable_items_out_of_trial_for_site! for site with at least a billable item out of trial' do
      @billable_items_will_receive_email.each do |billable_item|
        BillingMailer.should delay(:trial_will_expire).with(billable_item.id)
      end

      described_class.send_trial_will_expire_email
    end
  end

  describe '.activate_billable_items_out_of_trial!' do
    before do
      Timecop.travel(15.days.ago) do
        create(:billable_item, site: site0, item: app_design_paid1, state: 'trial')
      end
      Timecop.travel(31.days.ago) do
        create(:billable_item, site: site1, item: app_design_paid1, state: 'trial')
        create(:billable_item, site: site2, item: addon_plan_paid1, state: 'trial')
        @billable_item3 = create(:billable_item, site: site3, item: addon_plan_paid1, state: 'trial')
        create(:billable_item, site: archived_site, item: addon_plan_paid1, state: 'trial')
      end
      @billable_item3.update_attribute(:state, 'subscribed')
    end

    it 'delays .activate_billable_items_out_of_trial_for_site! for site with at least a billable item out of trial' do
      described_class.should delay(:activate_billable_items_out_of_trial_for_site!).with(site1.id)
      described_class.should delay(:activate_billable_items_out_of_trial_for_site!).with(site2.id)

      described_class.activate_billable_items_out_of_trial!
    end
  end

  describe '.activate_billable_items_out_of_trial_for_site!' do
    before do
      Timecop.travel(15.days.ago) do
        create(:billable_item, site: site1, item: app_design_paid1, state: 'trial')
      end
      Timecop.travel(31.days.ago) do
        create(:billable_item, site: site1, item: app_design_paid2, state: 'trial')
        create(:billable_item, site: site1, item: addon_plan_paid1, state: 'trial')
        create(:billable_item, site: site1, item: addon_plan_paid2, state: 'trial')
      end
      site1.out_of_trial?(app_design_paid1).should be_false
      site1.out_of_trial?(app_design_paid2).should be_true
      site1.out_of_trial?(addon_plan_paid1).should be_true
      site1.out_of_trial?(addon_plan_paid2).should be_true
      site1.billable_items.should have(4).items
    end

    context 'user has a cc' do
      it 'delegates to Service::Site#update_billable_items with the app designs and addon plans IDs' do
        described_class.activate_billable_items_out_of_trial_for_site!(site1.id)

        design_billable_items = site1.billable_items.app_designs
        addon_billable_items  = site1.billable_items.addon_plans

        site1.reload.billable_items.should have(4).items
        design_billable_items.where(item_id: app_design_paid1).where(state: 'trial').should have(1).item

        design_billable_items.where(item_id: app_design_paid2).where(state: 'subscribed').should have(1).item

        addon_billable_items.where(item_id: addon_plan_paid1).where(state: 'subscribed').should have(1).item

        addon_billable_items.where(item_id: addon_plan_paid2).where(state: 'subscribed').should have(1).item


        design_billable_item_activities = site1.billable_item_activities.app_designs
        addon_billable_item_activities  = site1.billable_item_activities.addon_plans

        site1.billable_item_activities.should have(4 + 3).items
        site1.billable_item_activities.app_designs.where(item_id: app_design_paid1).where(state: 'trial').should have(1).item

        site1.billable_item_activities.app_designs.where(item_id: app_design_paid2).where(state: 'trial').should have(1).item
        site1.billable_item_activities.app_designs.where(item_id: app_design_paid2).where(state: 'subscribed').should have(1).item

        site1.billable_item_activities.addon_plans.where(item_id: addon_plan_paid1).where(state: 'trial').should have(1).item
        site1.billable_item_activities.addon_plans.where(item_id: addon_plan_paid1).where(state: 'subscribed').should have(1).item

        site1.billable_item_activities.addon_plans.where(item_id: addon_plan_paid2).where(state: 'trial').should have(1).item
        site1.billable_item_activities.addon_plans.where(item_id: addon_plan_paid2).where(state: 'subscribed').should have(1).item
      end
    end

    context 'user has no cc' do
      let(:user) { create(:user_no_cc) }

      it 'delegates to Service::Site#update_billable_items and cancel the app designs and addon plans IDs' do
        BillingMailer.should delay(:trial_has_expired).with(site1.id, 'App::Design', app_design_paid2.id)
        BillingMailer.should delay(:trial_has_expired).with(site1.id, 'AddonPlan', addon_plan_paid1.id)

        described_class.activate_billable_items_out_of_trial_for_site!(site1.id)

        design_billable_items = site1.billable_items.app_designs
        addon_billable_items  = site1.billable_items.addon_plans

        site1.reload.billable_items.should have(2).items
        design_billable_items.where(item_id: app_design_paid1).where(state: 'trial').should have(1).item

        addon_billable_items.where(item_id: @free_addon_plan).where(state: 'subscribed').should have(1).item


        design_billable_item_activities = site1.billable_item_activities.app_designs
        addon_billable_item_activities  = site1.billable_item_activities.addon_plans

        site1.reload.billable_item_activities.should have(4 + 4).item
        design_billable_item_activities.where(item_id: app_design_paid1).where(state: 'trial').should have(1).item

        design_billable_item_activities.where(item_id: app_design_paid2).where(state: 'trial').should have(1).item
        design_billable_item_activities.where(item_id: app_design_paid2).where(state: 'canceled').should have(1).item

        addon_billable_item_activities.where(item_id: addon_plan_paid1).where(state: 'trial').should have(1).item
        addon_billable_item_activities.where(item_id: addon_plan_paid1).where(state: 'canceled').should have(1).item
        addon_billable_item_activities.where(item_id: @free_addon_plan).where(state: 'subscribed').should have(1).item

        addon_billable_item_activities.where(item_id: addon_plan_paid2).where(state: 'trial').should have(1).item
        addon_billable_item_activities.where(item_id: addon_plan_paid2).where(state: 'canceled').should have(1).item
      end

      context 'an issue occurs' do
        before do
          service = stub
          Service::Site.should_receive(:new) { service }
          service.should_receive(:update_billable_items).and_raise Exception
        end

        it 'do not send emails if there is any issue during Service::Site#update_billable_items' do
          BillingMailer.should_not delay(:trial_has_expired)

          expect { described_class.activate_billable_items_out_of_trial_for_site!(site1.id) }.to raise_error(Exception)
        end
      end
    end
  end

end
