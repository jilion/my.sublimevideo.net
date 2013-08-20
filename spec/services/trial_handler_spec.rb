require 'spec_helper'

describe TrialHandler do
  let(:user)             { create(:user) }
  let(:site)             { create(:site, user: user) }
  let(:site1)            { create(:site, user: user) }
  let(:site2)            { create(:site, user: user) }
  let(:site3)            { create(:site, user: user) }
  let(:archived_site)    { create(:site, user: user, state: 'archived') }
  let(:design_paid1)     { create(:design, price: 995) }
  let(:design_paid2)     { create(:design, price: 995) }
  let(:addon)            { create(:addon) }
  let(:addon2)           { create(:addon) }
  let!(:free_addon_plan) { create(:addon_plan, addon: addon,  price: 0) }
  let(:addon_plan_paid1) { create(:addon_plan, addon: addon,  price: 995) }
  let(:addon_plan_paid2) { create(:addon_plan, addon: addon2, price: 1995) }

  describe '.send_trial_will_expire_emails' do
    let!(:beta_subscription)       { create(:billable_item, site: site, state: 'beta') }
    let!(:trial_subscription)      { create(:billable_item, site: site1, state: 'trial') }
    let!(:subscribed_subscription) { create(:billable_item, site: site2, state: 'subscribed') }
    let!(:sponsored_subscription)  { create(:billable_item, site: site3, state: 'sponsored') }

    it 'delay ._send_trial_will_expire_emails for site with trial subscriptions' do
      described_class.should delay(:_send_trial_will_expire_emails).with(site1.id)

      described_class.send_trial_will_expire_emails
    end
  end

  describe '#send_trial_will_expire_emails' do
    before do
      @billable_items_wont_receive_email = [create(:billable_item, site: site, state: 'trial')]
      @billable_items_will_receive_email = []

      BusinessModel.days_before_trial_end.each do |days_before_trial_end|
        Timecop.travel((BusinessModel.days_for_trial - days_before_trial_end + 1).days.ago) do
          @billable_items_wont_receive_email << create(:billable_item, site: site, state: 'subscribed')
          @billable_items_will_receive_email << create(:billable_item, site: site, state: 'trial')
        end
      end
    end

    it 'delays BillingMailer#trial_will_expire for site with at least a billable item out of trial' do
      @billable_items_will_receive_email.each do |billable_item|
        BillingMailer.should delay(:trial_will_expire).with(billable_item.id)
      end

      described_class.new(site).send_trial_will_expire_emails
    end
  end

  describe '.activate_billable_items_out_of_trial' do
    before do
      Timecop.travel((BusinessModel.days_for_trial / 2).days.ago) do
        create(:billable_item, site: site, item: design_paid1, state: 'trial')
      end
      Timecop.travel((BusinessModel.days_for_trial + 1).days.ago) do
        create(:billable_item, site: site1, item: design_paid1, state: 'trial')
        create(:billable_item, site: site2, item: addon_plan_paid1, state: 'trial')
        @billable_item3 = create(:billable_item, site: site3, item: addon_plan_paid1, state: 'trial')
        create(:billable_item, site: archived_site, item: addon_plan_paid1, state: 'trial')
      end
      @billable_item3.update_attribute(:state, 'subscribed')
    end

    it 'delays ._activate_billable_items_out_of_trial for site with trial subscriptions' do
      described_class.should delay(:_activate_billable_items_out_of_trial).several_times_with(site.id, site1.id, site2.id)

      described_class.activate_billable_items_out_of_trial
    end
  end

  describe '#activate_billable_items_out_of_trial' do
    before do
      Timecop.travel((BusinessModel.days_for_trial / 2).days.ago) do
        create(:billable_item, site: site1, item: design_paid1, state: 'trial')
      end
      Timecop.travel((BusinessModel.days_for_trial + 1).days.ago) do
        create(:billable_item, site: site1, item: design_paid2, state: 'trial')
        create(:billable_item, site: site1, item: addon_plan_paid1, state: 'trial')
        create(:billable_item, site: site1, item: addon_plan_paid2, state: 'trial')
      end
      described_class.new(site1).out_of_trial?(design_paid1).should be_false
      described_class.new(site1).out_of_trial?(design_paid2).should be_true
      described_class.new(site1).out_of_trial?(addon_plan_paid1).should be_true
      described_class.new(site1).out_of_trial?(addon_plan_paid2).should be_true
      site1.billable_items.should have(4).items
    end

    context 'user has a cc' do
      it 'delegates to SiteManager#update_billable_items with the app designs and addon plans IDs' do
        described_class.new(site1).activate_billable_items_out_of_trial

        site1.reload.billable_items.should have(4).items
        site1.billable_items.with_item(design_paid1)    .state('trial').should have(1).item
        site1.billable_items.with_item(design_paid2)    .state('subscribed').should have(1).item
        site1.billable_items.with_item(addon_plan_paid1).state('subscribed').should have(1).item
        site1.billable_items.with_item(addon_plan_paid2).state('subscribed').should have(1).item

        site1.billable_item_activities.should have(4 + 3).items
        site1.billable_item_activities.with_item(design_paid1).state('trial').should have(1).item
        site1.billable_item_activities.with_item(design_paid2).state('trial').should have(1).item
        site1.billable_item_activities.with_item(design_paid2).state('subscribed').should have(1).item
        site1.billable_item_activities.with_item(addon_plan_paid1).state('trial').should have(1).item
        site1.billable_item_activities.with_item(addon_plan_paid1).state('subscribed').should have(1).item
        site1.billable_item_activities.with_item(addon_plan_paid2).state('trial').should have(1).item
        site1.billable_item_activities.with_item(addon_plan_paid2).state('subscribed').should have(1).item
      end
    end

    context 'user has no cc' do
      let(:user) { create(:user_no_cc) }

      it 'delegates to SiteManager#update_billable_items and cancel the app designs and addon plans IDs' do
        BillingMailer.should delay(:trial_has_expired).several_times_with(
          [site1.id, 'AddonPlan', addon_plan_paid2.id],
          [site1.id, 'AddonPlan', addon_plan_paid1.id],
          [site1.id, 'Design', design_paid2.id]
        )

        described_class.new(site1).activate_billable_items_out_of_trial

        site1.reload.billable_items.should have(2).items
        site1.billable_items.with_item(design_paid1).state('trial').should have(1).item
        site1.billable_items.with_item(free_addon_plan).state('subscribed').should have(1).item

        site1.reload.billable_item_activities.should have(4 + 4).item
        site1.billable_item_activities.with_item(design_paid1).state('trial').should have(1).item
        site1.billable_item_activities.with_item(design_paid2).state('trial').should have(1).item
        site1.billable_item_activities.with_item(design_paid2).state('canceled').should have(1).item
        site1.billable_item_activities.with_item(addon_plan_paid1).state('trial').should have(1).item
        site1.billable_item_activities.with_item(addon_plan_paid1).state('canceled').should have(1).item
        site1.billable_item_activities.with_item(free_addon_plan).state('subscribed').should have(1).item
        site1.billable_item_activities.with_item(addon_plan_paid2).state('trial').should have(1).item
        site1.billable_item_activities.with_item(addon_plan_paid2).state('canceled').should have(1).item
      end

      context 'an issue occurs' do
        before do
          service = double
          SiteManager.should_receive(:new) { service }
          service.should_receive(:update_billable_items).and_raise Exception
        end

        it 'do not send emails if there is any issue during SiteManager#update_billable_items' do
          BillingMailer.should_not delay(:trial_has_expired)

          expect { described_class.new(site1).activate_billable_items_out_of_trial }.to raise_error(Exception)
        end
      end
    end

  end

  describe '#trial_ends_on?' do
    let(:subscription_history1) { create(:billable_item_activity, site: site, state: 'trial', created_at: (BusinessModel.days_for_trial - 1).days.ago) }
    let(:subscription_history2) { create(:billable_item_activity, site: site, state: 'beta', created_at: BusinessModel.days_for_trial.days.ago) }
    let(:subscription_history3) { create(:billable_item_activity, site: site, state: 'subscribed', created_at: (BusinessModel.days_for_trial + 1).days.ago) }

    it { described_class.new(site).trial_ends_on?(subscription_history1.item, 5.days.from_now).should be_false }
    it { described_class.new(site).trial_ends_on?(subscription_history1.item, 2.days.from_now).should be_true }
    it { described_class.new(site).trial_ends_on?(subscription_history1.item, 1.day.from_now).should be_false }

    it { described_class.new(site).trial_ends_on?(subscription_history2.item, 2.days.from_now).should be_false }
    it { described_class.new(site).trial_ends_on?(subscription_history2.item, 1.day.from_now).should be_false }

    it { described_class.new(site).trial_ends_on?(subscription_history3.item, 1.day.ago).should be_false }
  end

  describe '#out_of_trial?' do
    let!(:subscription_history1) { create(:billable_item_activity, site: site, state: 'trial', created_at: (BusinessModel.days_for_trial - 1).days.ago) }
    let!(:subscription_history2) { create(:billable_item_activity, site: site, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) }
    let!(:subscription)          { create(:billable_item, site: site, state: 'subscribed') }

    it { described_class.new(site).out_of_trial?(subscription_history1.item).should be_false }
    it { described_class.new(site).out_of_trial?(subscription_history2.item).should be_true }
    it { described_class.new(site).out_of_trial?(subscription.item).should be_true }
  end

  describe '#trial_days_remaining' do
    let(:addon_plan1) { create(:addon_plan) }
    let(:addon_plan2) { create(:addon_plan) }
    let(:subscription) { create(:billable_item, site: site, state: 'subscribed') }
    let(:billable_item_activity1) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: (BusinessModel.days_for_trial + 1).days.ago) }
    let(:billable_item_activity2) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: BusinessModel.days_for_trial.days.ago) }
    let(:billable_item_activity3) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: (BusinessModel.days_for_trial - 1).days.ago) }
    let(:billable_item_activity4) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: (BusinessModel.days_for_trial - 2).days.ago) }
    let(:billable_item_activity5) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: (BusinessModel.days_for_trial / 2).days.ago) }
    let(:billable_item_activity6) { create(:billable_item_activity, item: addon_plan1, state: 'trial') }

    it 'works' do
      described_class.new(billable_item_activity1.site).trial_days_remaining(addon_plan1).should eq 0
      described_class.new(billable_item_activity2.site).trial_days_remaining(addon_plan1).should eq 0
      described_class.new(billable_item_activity3.site).trial_days_remaining(addon_plan1).should eq 1
      described_class.new(billable_item_activity4.site).trial_days_remaining(addon_plan1).should eq 2
      described_class.new(billable_item_activity5.site).trial_days_remaining(addon_plan1).should eq (BusinessModel.days_for_trial / 2.0).round
      described_class.new(billable_item_activity6.site).trial_days_remaining(addon_plan1).should eq BusinessModel.days_for_trial
      described_class.new(site).trial_days_remaining(subscription.item).should eq 0
      described_class.new(site).trial_days_remaining(addon_plan2).should be_nil
      described_class.new(create(:site)).trial_days_remaining(addon_plan1).should be_nil
    end
  end

  describe '#trial_end_date' do
    let(:addon_plan1) { create(:addon_plan, created_at: (BusinessModel.days_for_trial + 1).days.from_now) }
    let(:addon_plan2) { create(:addon_plan) }
    let(:billable_item_activity1) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: (BusinessModel.days_for_trial + 1).days.ago.midnight) }
    let(:billable_item_activity2) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: BusinessModel.days_for_trial.days.ago.midnight) }
    let(:billable_item_activity3) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: (BusinessModel.days_for_trial - 1).days.ago.midnight) }
    let(:billable_item_activity4) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: (BusinessModel.days_for_trial - 2).days.ago.midnight) }
    let(:billable_item_activity5) { create(:billable_item_activity, item: addon_plan1, state: 'trial', created_at: Time.now.utc) }

    it 'works' do
      described_class.new(billable_item_activity1.site).trial_end_date(addon_plan1).should eq 1.day.ago.midnight
      described_class.new(billable_item_activity2.site).trial_end_date(addon_plan1).should eq Time.now.utc.midnight
      described_class.new(billable_item_activity3.site).trial_end_date(addon_plan1).should eq 1.day.from_now.midnight
      described_class.new(billable_item_activity4.site).trial_end_date(addon_plan1).should eq 2.days.from_now.midnight
      described_class.new(billable_item_activity5.site).trial_end_date(addon_plan1).midnight.should eq BusinessModel.days_for_trial.days.from_now.midnight
      described_class.new(create(:site)).trial_days_remaining(addon_plan1).should be_nil
    end
  end

end
