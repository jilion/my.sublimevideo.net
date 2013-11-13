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
      expect(described_class).to delay(:_send_trial_will_expire_emails).with(site1.id)

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
        expect(BillingMailer).to delay(:trial_will_expire).with(billable_item.id)
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
      expect(described_class).to delay(:_activate_billable_items_out_of_trial).several_times_with(site.id, site1.id, site2.id)

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
      expect(described_class.new(site1).out_of_trial?(design_paid1)).to be_falsey
      expect(described_class.new(site1).out_of_trial?(design_paid2)).to be_truthy
      expect(described_class.new(site1).out_of_trial?(addon_plan_paid1)).to be_truthy
      expect(described_class.new(site1).out_of_trial?(addon_plan_paid2)).to be_truthy
      expect(site1.billable_items.size).to eq(4)
    end

    context 'user has a cc' do
      it 'delegates to SiteManager#update_billable_items with the app designs and addon plans IDs' do
        described_class.new(site1).activate_billable_items_out_of_trial

        expect(site1.reload.billable_items.size).to eq(4)
        expect(site1.billable_items.with_item(design_paid1)    .state('trial').size).to eq(1)
        expect(site1.billable_items.with_item(design_paid2)    .state('subscribed').size).to eq(1)
        expect(site1.billable_items.with_item(addon_plan_paid1).state('subscribed').size).to eq(1)
        expect(site1.billable_items.with_item(addon_plan_paid2).state('subscribed').size).to eq(1)

        expect(site1.billable_item_activities.size).to eq(4 + 3)
        expect(site1.billable_item_activities.with_item(design_paid1).state('trial').size).to eq(1)
        expect(site1.billable_item_activities.with_item(design_paid2).state('trial').size).to eq(1)
        expect(site1.billable_item_activities.with_item(design_paid2).state('subscribed').size).to eq(1)
        expect(site1.billable_item_activities.with_item(addon_plan_paid1).state('trial').size).to eq(1)
        expect(site1.billable_item_activities.with_item(addon_plan_paid1).state('subscribed').size).to eq(1)
        expect(site1.billable_item_activities.with_item(addon_plan_paid2).state('trial').size).to eq(1)
        expect(site1.billable_item_activities.with_item(addon_plan_paid2).state('subscribed').size).to eq(1)
      end
    end

    context 'user has no cc' do
      let(:user) { create(:user_no_cc) }

      it 'delegates to SiteManager#update_billable_items and cancel the app designs and addon plans IDs' do
        expect(BillingMailer).to delay(:trial_has_expired).several_times_with(
          [site1.id, 'AddonPlan', addon_plan_paid2.id],
          [site1.id, 'AddonPlan', addon_plan_paid1.id],
          [site1.id, 'Design', design_paid2.id]
        )

        described_class.new(site1).activate_billable_items_out_of_trial

        expect(site1.reload.billable_items.size).to eq(2)
        expect(site1.billable_items.with_item(design_paid1).state('trial').size).to eq(1)
        expect(site1.billable_items.with_item(free_addon_plan).state('subscribed').size).to eq(1)

        expect(site1.reload.billable_item_activities.size).to eq(4 + 4)
        expect(site1.billable_item_activities.with_item(design_paid1).state('trial').size).to eq(1)
        expect(site1.billable_item_activities.with_item(design_paid2).state('trial').size).to eq(1)
        expect(site1.billable_item_activities.with_item(design_paid2).state('canceled').size).to eq(1)
        expect(site1.billable_item_activities.with_item(addon_plan_paid1).state('trial').size).to eq(1)
        expect(site1.billable_item_activities.with_item(addon_plan_paid1).state('canceled').size).to eq(1)
        expect(site1.billable_item_activities.with_item(free_addon_plan).state('subscribed').size).to eq(1)
        expect(site1.billable_item_activities.with_item(addon_plan_paid2).state('trial').size).to eq(1)
        expect(site1.billable_item_activities.with_item(addon_plan_paid2).state('canceled').size).to eq(1)
      end

      context 'an issue occurs' do
        before do
          service = double
          expect(SiteManager).to receive(:new) { service }
          expect(service).to receive(:update_billable_items).and_raise Exception
        end

        it 'do not send emails if there is any issue during SiteManager#update_billable_items' do
          expect(BillingMailer).not_to delay(:trial_has_expired)

          expect { described_class.new(site1).activate_billable_items_out_of_trial }.to raise_error(Exception)
        end
      end
    end

  end

  describe '#trial_ends_on?' do
    let(:subscription_history1) { create(:billable_item_activity, site: site, state: 'trial', created_at: (BusinessModel.days_for_trial - 1).days.ago) }
    let(:subscription_history2) { create(:billable_item_activity, site: site, state: 'beta', created_at: BusinessModel.days_for_trial.days.ago) }
    let(:subscription_history3) { create(:billable_item_activity, site: site, state: 'subscribed', created_at: (BusinessModel.days_for_trial + 1).days.ago) }

    it { expect(described_class.new(site).trial_ends_on?(subscription_history1.item, 5.days.from_now)).to be_falsey }
    it { expect(described_class.new(site).trial_ends_on?(subscription_history1.item, 2.days.from_now)).to be_truthy }
    it { expect(described_class.new(site).trial_ends_on?(subscription_history1.item, 1.day.from_now)).to be_falsey }

    it { expect(described_class.new(site).trial_ends_on?(subscription_history2.item, 2.days.from_now)).to be_falsey }
    it { expect(described_class.new(site).trial_ends_on?(subscription_history2.item, 1.day.from_now)).to be_falsey }

    it { expect(described_class.new(site).trial_ends_on?(subscription_history3.item, 1.day.ago)).to be_falsey }
  end

  describe '#out_of_trial?' do
    let!(:subscription_history1) { create(:billable_item_activity, site: site, state: 'trial', created_at: (BusinessModel.days_for_trial - 1).days.ago) }
    let!(:subscription_history2) { create(:billable_item_activity, site: site, state: 'beta', created_at: (BusinessModel.days_for_trial + 1).days.ago) }
    let!(:subscription)          { create(:billable_item, site: site, state: 'subscribed') }

    it { expect(described_class.new(site).out_of_trial?(subscription_history1.item)).to be_falsey }
    it { expect(described_class.new(site).out_of_trial?(subscription_history2.item)).to be_truthy }
    it { expect(described_class.new(site).out_of_trial?(subscription.item)).to be_truthy }
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
      expect(described_class.new(billable_item_activity1.site).trial_days_remaining(addon_plan1)).to eq 0
      expect(described_class.new(billable_item_activity2.site).trial_days_remaining(addon_plan1)).to eq 0
      expect(described_class.new(billable_item_activity3.site).trial_days_remaining(addon_plan1)).to eq 1
      expect(described_class.new(billable_item_activity4.site).trial_days_remaining(addon_plan1)).to eq 2
      expect(described_class.new(billable_item_activity5.site).trial_days_remaining(addon_plan1)).to eq (BusinessModel.days_for_trial / 2.0).round
      expect(described_class.new(billable_item_activity6.site).trial_days_remaining(addon_plan1)).to eq BusinessModel.days_for_trial
      expect(described_class.new(site).trial_days_remaining(subscription.item)).to eq 0
      expect(described_class.new(site).trial_days_remaining(addon_plan2)).to be_nil
      expect(described_class.new(create(:site)).trial_days_remaining(addon_plan1)).to be_nil
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
      expect(described_class.new(billable_item_activity1.site).trial_end_date(addon_plan1)).to eq 1.day.ago.midnight
      expect(described_class.new(billable_item_activity2.site).trial_end_date(addon_plan1)).to eq Time.now.utc.midnight
      expect(described_class.new(billable_item_activity3.site).trial_end_date(addon_plan1)).to eq 1.day.from_now.midnight
      expect(described_class.new(billable_item_activity4.site).trial_end_date(addon_plan1)).to eq 2.days.from_now.midnight
      expect(described_class.new(billable_item_activity5.site).trial_end_date(addon_plan1).midnight).to eq BusinessModel.days_for_trial.days.from_now.midnight
      expect(described_class.new(create(:site)).trial_days_remaining(addon_plan1)).to be_nil
    end
  end

end
