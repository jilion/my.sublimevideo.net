require 'spec_helper'

describe SiteModules::Invoice do
  describe "Class Methods" do

    describe ".send_trial_will_expire", :plans do
      before(:all) do
        @user_without_cc    = create(:user_no_cc)
        @user_with_cc       = create(:user)
        @sites_not_in_trial = [create(:site, trial_started_at: BusinessModel.days_for_trial.days.ago)]
        @sites_in_trial     = []

        BusinessModel.days_before_trial_end.each do |days_before_trial_end|
          @sites_not_in_trial << create(:site, user: @user_without_cc, state: 'archived', trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago)
          @sites_not_in_trial << create(:site, user: @user_without_cc, trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago, first_paid_plan_started_at: 2.months.ago)
          @sites_not_in_trial << create(:site, user: @user_with_cc, trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago)
          @sites_in_trial << create(:site, user: @user_without_cc, trial_started_at: (BusinessModel.days_for_trial - days_before_trial_end).days.ago)
        end
      end
      after(:all) { DatabaseCleaner.clean_with(:truncation) }

      it "delays itself" do
        Site.should_receive(:send_trial_will_expire)
        Site.send_trial_will_expire
      end

      it "sends 'trial will end' email" do
        ActionMailer::Base.deliveries.clear
        expect { Site.send_trial_will_expire }.to change(ActionMailer::Base.deliveries, :size).by(@sites_in_trial.size)
      end

      context "when we move 2 days in the future" do
        it "doesn't send 'trial will end' email" do
          ActionMailer::Base.deliveries.clear
          Timecop.travel(2.days.from_now) { expect { Site.send_trial_will_expire }.to_not change(ActionMailer::Base.deliveries, :size) }
        end
      end
    end

    describe ".activate_or_downgrade_sites_leaving_trial", :plans do
      before(:all) do
        @site_in_trial                = create(:site, trial_started_at: Time.now.tomorrow)
        @site_not_in_trial_without_cc = create(:site, user: create(:user_no_cc))
        @site_not_in_trial_with_cc_1  = create(:site)
        @site_not_in_trial_with_cc_2  = create(:site)
        @site_not_in_trial_with_cc_2.update_attribute(:plan_id, @free_plan.id)
        @site_not_in_trial_with_cc_2.should be_in_free_plan

        [@site_in_trial, @site_not_in_trial_without_cc, @site_not_in_trial_with_cc_1, @site_not_in_trial_with_cc_2].each { |site| site.invoices.should be_empty }
      end
      after(:all) { DatabaseCleaner.clean_with(:truncation) }

      before do
        [@site_in_trial, @site_not_in_trial_without_cc, @site_not_in_trial_with_cc_1, @site_not_in_trial_with_cc_2].each { |site| site.reload }

        %w[pending_plan_cycle_started_at pending_plan_cycle_ended_at first_paid_plan_started_at].each do |attr|
          [@site_in_trial, @site_not_in_trial_without_cc, @site_not_in_trial_with_cc_1, @site_not_in_trial_with_cc_2].each { |site| site.send(attr).should be_nil }
        end
        Delayed::Job.delete_all
      end

      shared_examples "don't charge invoice" do
        it { Transaction.should_not_receive(:charge_by_invoice_ids) }
      end

      shared_examples "site that can't be activated" do
        it "doesn't create invoice" do
          site.reload.invoices.should be_empty
        end

        it "doesn't update plan cycle dates" do
          %w[pending_plan_cycle_started_at pending_plan_cycle_ended_at first_paid_plan_started_at].each do |attr|
            site.send(attr).should be_nil
          end
        end
      end

      describe "non-activatable sites (1)" do
        it_behaves_like "don't charge invoice"

        it_behaves_like "site that can't be activated" do
          let(:site) { @site_in_trial.reload }
        end
      end

      describe "non-activatable sites (2)" do
        before do
          Timecop.travel(BusinessModel.days_for_trial.days.from_now) { Site.activate_or_downgrade_sites_leaving_trial }
        end
        subject { @site_not_in_trial_with_cc_2.reload }

        it_behaves_like "don't charge invoice"

        it_behaves_like "site that can't be activated" do
          let(:site) { @site_not_in_trial_with_cc_2.reload }
        end
      end

      describe "activatable sites belonging to a user without credit card" do
        before do
          Timecop.travel(BusinessModel.days_for_trial.days.from_now) { Site.activate_or_downgrade_sites_leaving_trial }
        end
        subject { @site_not_in_trial_without_cc.reload }

        it_behaves_like "don't charge invoice"

        it_behaves_like "site that can't be activated" do
          let(:site) { @site_not_in_trial_without_cc.reload }
        end

        it "downgrade to free plan" do
          subject.plan_id.should eql @free_plan.id
        end
      end

      describe "activatable sites belonging to a user with credit card" do
        before do
          Timecop.travel(BusinessModel.days_for_trial.days.from_now) { Site.activate_or_downgrade_sites_leaving_trial }
        end
        subject { @site_not_in_trial_with_cc_1.reload }

        it_behaves_like "don't charge invoice"

        it "creates a non-renew invoice" do
          subject.invoices.should have(1).item
          subject.invoices.by_date('asc').last.should_not be_renew
          subject.invoices.by_date('asc').last.amount.should > 0
        end

        %w[pending_plan_cycle_started_at pending_plan_cycle_ended_at first_paid_plan_started_at].each do |attr|
          it "updates #{attr}" do
            subject.send(attr).should be_present
          end
        end
      end
    end # .activate_or_downgrade_sites_leaving_trial

    describe ".renew_active_sites", :plans do
      before(:all) do
        Timecop.travel(2.months.ago) do
          @site_renewable = create(:site_with_invoice)
          @site_renewable_with_downgrade_to_free_plan = create(:site_with_invoice)
          @site_renewable_with_downgrade_to_free_plan.update_attribute(:next_cycle_plan_id, @free_plan.id)
          @site_renewable_with_downgrade_to_paid_plan = create(:site_with_invoice, plan_id: @custom_plan.token)
          @site_renewable_with_downgrade_to_paid_plan.update_attribute(:next_cycle_plan_id, @paid_plan.id)
        end
        @site_not_renewable = create(:site_with_invoice, plan_started_at: 3.months.ago, plan_cycle_ended_at: 2.months.from_now)

        @site_renewable.invoices.paid.should have(1).item
        @site_renewable_with_downgrade_to_free_plan.invoices.paid.should have(1).item
        @site_renewable_with_downgrade_to_paid_plan.invoices.paid.should have(1).item
        @site_not_renewable.invoices.paid.should have(1).item
      end
      after(:all) { DatabaseCleaner.clean_with(:truncation) }

      before do
        @site_renewable.reload
        @site_renewable_with_downgrade_to_free_plan.reload
        @site_renewable_with_downgrade_to_paid_plan.reload
        @site_not_renewable.reload

        @site_renewable.pending_plan_cycle_started_at.should be_nil
        @site_renewable.pending_plan_cycle_ended_at.should be_nil

        Transaction.should_not_receive(:charge_by_invoice_ids)

        Delayed::Job.delete_all
        Site.renew_active_sites
      end

      it "creates invoices for renewable sites only" do
        @site_not_renewable.reload.invoices.should have(1).items
        @site_renewable_with_downgrade_to_free_plan.reload.invoices.should have(1).items

        @site_renewable.reload.invoices.should have(2).items
        @site_renewable_with_downgrade_to_paid_plan.reload.invoices.should have(2).items
      end

      it "updates plan cycle dates for renewable sites only" do
        [@site_not_renewable, @site_renewable_with_downgrade_to_free_plan].each do |site|
          site.reload.pending_plan_cycle_started_at.should be_nil
          site.pending_plan_cycle_ended_at.should be_nil
        end

        [@site_renewable, @site_renewable_with_downgrade_to_paid_plan].each do |site|
          site.reload.pending_plan_cycle_started_at.should be_present
          site.pending_plan_cycle_ended_at.should be_present
        end
      end

      it "updates plan of downgraded sites" do
        @site_renewable_with_downgrade_to_free_plan.reload.next_cycle_plan_id.should be_nil
        @site_renewable_with_downgrade_to_free_plan.reload.plan_id.should eql @free_plan.id

        @site_renewable_with_downgrade_to_paid_plan.reload.next_cycle_plan_id.should be_nil
        @site_renewable_with_downgrade_to_paid_plan.reload.pending_plan_id.should eql @paid_plan.id
      end

      it "sets the renew flag to true" do
        @site_not_renewable.reload.invoices.by_date('asc').last.should_not be_renew
        @site_renewable.reload.invoices.by_date('asc').last.should be_renew
        @site_renewable_with_downgrade_to_free_plan.reload.invoices.by_date('asc').last.should_not be_renew
        @site_renewable_with_downgrade_to_paid_plan.reload.invoices.by_date('asc').last.should be_renew
      end
    end # .renew_active_sites

  end # Class Methods

  describe "Instance Methods", :plans do

    %w[trial_started_at first_paid_plan_started_at pending_plan_started_at pending_plan_cycle_started_at].each do |attr|
      describe "##{attr}=" do
        subject { build(:new_site) }

        it "accepts nil" do
          subject.send("#{attr}=", nil)

          subject.send(attr).should be_nil
        end

        it "sets given date to midnight" do
          subject.send("#{attr}=", Time.now.utc)

          subject.send(attr).should eql Time.now.utc.midnight
        end
      end
    end

    describe "#pending_plan_cycle_ended_at=" do
      subject { build(:new_site) }

      it "accepts nil" do
        subject.pending_plan_cycle_ended_at = nil

        subject.pending_plan_cycle_ended_at.should be_nil
      end

      it "sets given date to midnight" do
        subject.pending_plan_cycle_ended_at = Time.now.utc

        subject.pending_plan_cycle_ended_at.should eql Time.now.utc.to_datetime.end_of_day
      end
    end

    describe "#invoices_failed?" do
      subject do
        site = create(:site)
        create(:invoice, site: site , state: 'failed')
        site
      end

      its(:invoices_failed?) { should be_true }
    end

    describe "#invoices_waiting?" do
      subject do
        site = create(:site)
        create(:invoice, site: site , state: 'waiting')
        site
      end

      its(:invoices_waiting?) { should be_true }
    end

    describe "#invoices_open?" do
      let(:site) { create(:site) }

      context "with no options" do
        it "should be true if invoice have the renew flag == false" do
          invoice = create(:invoice, state: 'open', site: site, renew: false)
          invoice.renew.should be_false
          site.invoices_open?.should be_true
        end

        it "should be true if invoice have the renew flag == true" do
          invoice = create(:invoice, state: 'open', site: site, renew: true)
          invoice.renew.should be_true
          site.invoices_open?.should be_true
        end
      end
    end

    describe "#in_free_plan?" do
      subject { create(:site, plan_id: @free_plan.id) }

      it { should be_in_free_plan }
    end # #in_free_plan?

    describe "#in_sponsored_plan?" do
      subject { site = create(:site); site.sponsor!; site.reload }

      it { should be_in_sponsored_plan }
    end # #in_sponsored_plan?

    describe "#in_paid_plan?" do
      context "standard plan" do
        subject { create(:site, plan_id: @paid_plan.id) }
        it { should be_in_paid_plan }
      end

      context "custom plan" do
        subject { create(:site, plan_id: @custom_plan.token) }
        it { should be_in_paid_plan }
      end
    end # #in_paid_plan?

    describe "#prepare_activation" do
      context "site in trial" do
        subject { build(:site) }

        it "sets first_paid_plan_started_at" do
          subject.first_paid_plan_started_at.should be_nil

          subject.prepare_activation

          subject.first_paid_plan_started_at.should be_present
        end
      end

      context "site not in trial anymore" do
        subject { create(:site_with_invoice) }

        it "doesn't reset first_paid_plan_started_at" do
          subject.first_paid_plan_started_at.should be_present

          original_first_paid_plan_started_at = subject.first_paid_plan_started_at
          subject.prepare_activation

          subject.first_paid_plan_started_at.should eq original_first_paid_plan_started_at
        end
      end
    end

    describe "#prepare_trial_skipping" do
      context "site in trial" do
        subject { build(:new_site) }

        it "sets trial_started_at at a date that kills it immediately" do
          subject.trial_started_at.should be_nil

          subject.prepare_trial_skipping

          subject.trial_started_at.should be_present
          subject.should_not be_trial_not_started_or_in_trial
        end

        it "sets first_paid_plan_started_at" do
          subject.first_paid_plan_started_at.should be_nil

          subject.prepare_trial_skipping

          subject.first_paid_plan_started_at.should be_present
        end
      end

      context "site not in trial anymore" do
        subject { create(:site_with_invoice, trial_started_at: 30.days.ago) }

        it "resets trial_started_at" do
          subject.trial_started_at.should be_present

          original_trial_started_at = subject.trial_started_at
          subject.prepare_trial_skipping

          subject.trial_started_at.should_not eq original_trial_started_at
        end

        it "doesn't reset first_paid_plan_started_at" do
          subject.first_paid_plan_started_at.should be_present

          original_first_paid_plan_started_at = subject.first_paid_plan_started_at
          subject.prepare_trial_skipping

          subject.first_paid_plan_started_at.should eq original_first_paid_plan_started_at
        end
      end
    end

    describe "#instant_charging?" do
      subject { create(:site) }

      specify do
        subject.instance_variable_set("@instant_charging", false)
        should_not be_instant_charging
      end

      specify do
        subject.instance_variable_set("@instant_charging", true)
        should be_instant_charging
      end
    end # #instant_charging?

    describe "#will_be_in_free_plan?" do

      context "site in free plan" do
        subject { create(:site, plan_id: @free_plan.id) }

        it { should_not be_will_be_in_free_plan }
      end

      context "site in paid plan" do
        subject { create(:site, plan_id: @paid_plan.id) }

        it { should_not be_will_be_in_free_plan }
      end

      context "site in build free plan" do
        subject { build(:new_site, plan_id: @free_plan.id) }

        it { should be_will_be_in_free_plan }
      end

      context "site is paid and updated to free" do
        before do
          @site = create(:site, plan_id: @paid_plan.id)
          @site.plan_id = @free_plan.id
        end
        subject { @site }

        it { should be_will_be_in_free_plan }
      end
    end # #will_be_in_free_plan?

    describe "#will_be_in_paid_plan?" do
      context "site in paid plan" do
        subject { create(:site, plan_id: @paid_plan.id) }

        it { should_not be_will_be_in_paid_plan }
      end

      context "site is free and updated to paid" do
        before do
          @site = create(:site, plan_id: @free_plan.id)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        it { should be_will_be_in_paid_plan }
      end

      context "site is paid and updated to paid" do
        before do
          @site = create(:site, plan_id: @paid_plan.id)
          @new_plan = create(:plan, price: @paid_plan.price + 1000)
          @site.plan_id = @new_plan.id
        end
        subject { @site }

        its(:pending_plan_id) { should == @new_plan.id }
        it { should be_will_be_in_paid_plan }
      end

      context "site is paid and updated to free" do
        before do
          @site = create(:site, plan_id: @paid_plan.id)
          @site.plan_id = @free_plan.id
        end
        subject { @site }

        it { should_not be_will_be_in_paid_plan }
      end
    end # #will_be_in_paid_plan?

    describe "#in_or_will_be_in_paid_plan?" do
      context "site in paid plan" do
        subject { create(:site, plan_id: @paid_plan.id) }

        it { should be_in_or_will_be_in_paid_plan }
      end

      context "site is free and updated to paid" do
        before do
          @site = create(:site, plan_id: @free_plan.id)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        it { should be_in_or_will_be_in_paid_plan }
      end

      context "site is paid is now paid" do
        before do
          @site = create(:site, plan_id: @paid_plan.id)
          @site.plan_id = @free_plan.id
        end
        subject { @site }

        it { should be_in_or_will_be_in_paid_plan }
      end
    end # #in_or_will_be_in_paid_plan?

    describe "#in_trial?" do
      before do
        @site_in_trial1 = build(:site)
        @site_in_trial2 = create(:site)
        Timecop.travel((BusinessModel.days_for_trial-1).days.ago) { @site_in_trial3 = create(:site) }
        Timecop.travel((BusinessModel.days_for_trial+1).days.ago) { @site_not_in_trial1 = create(:site, plan_id: @free_plan.id) }
        Timecop.travel((BusinessModel.days_for_trial+1).days.ago) { @site_not_in_trial2 = create(:site) }
      end

      specify { @site_in_trial1.should be_in_trial }
      specify { @site_in_trial2.should be_in_trial }
      specify { @site_in_trial3.should be_in_trial }
      specify { @site_not_in_trial1.should_not be_in_trial }
      specify { @site_not_in_trial2.should_not be_in_trial }
    end

    describe "#trial_ended?" do
      before do
        @site_in_trial1 = build(:site)
        @site_in_trial2 = create(:site)
        Timecop.travel((BusinessModel.days_for_trial-1).days.ago) { @site_in_trial3 = create(:site) }
        Timecop.travel((BusinessModel.days_for_trial+1).days.ago) { @site_in_trial4 = create(:site, plan_id: @free_plan.id) }
        Timecop.travel((BusinessModel.days_for_trial+1).days.ago) { @site_not_in_trial = create(:site) }
      end

      specify { @site_in_trial1.should_not be_trial_ended }
      specify { @site_in_trial2.should_not be_trial_ended }
      specify { @site_in_trial3.should_not be_trial_ended }
      specify { @site_in_trial4.should_not be_trial_ended }
      specify { @site_not_in_trial.should be_trial_ended }
    end

    describe "#trial_not_started_or_in_trial?" do
      before do
        @site_in_trial1 = build(:site)
        @site_in_trial2 = create(:site)
        Timecop.travel((BusinessModel.days_for_trial-1).days.ago) { @site_in_trial3 = create(:site) }
        Timecop.travel((BusinessModel.days_for_trial+1).days.ago) { @site_in_trial4 = create(:site, plan_id: @free_plan.id) }
        Timecop.travel((BusinessModel.days_for_trial+1).days.ago) { @site_not_in_trial = create(:site) }
      end

      specify { @site_in_trial1.should be_trial_not_started_or_in_trial }
      specify { @site_in_trial2.should be_trial_not_started_or_in_trial }
      specify { @site_in_trial3.should be_trial_not_started_or_in_trial }
      specify { @site_in_trial4.should be_trial_not_started_or_in_trial }
      specify { @site_not_in_trial.should_not be_trial_not_started_or_in_trial }
    end

    describe "#refunded?" do
      before do
        @site_refunded1     = create(:site, state: 'archived', refunded_at: Time.now.utc)
        @site_not_refunded1 = create(:site, state: 'active', refunded_at: Time.now.utc)
        @site_not_refunded2 = create(:site, state: 'archived', refunded_at: nil)
      end

      specify { @site_refunded1.should be_refunded }
      specify { @site_not_refunded1.should_not be_refunded }
      specify { @site_not_refunded2.should_not be_refunded }
    end

    describe "#last_paid_invoice" do
      context "with the last paid invoice not refunded" do
        subject { create(:site_with_invoice, plan_id: @paid_plan.id) }

        it "should return the last paid invoice" do
          subject.last_paid_invoice.should == subject.invoices.paid.last
        end
      end

      context "with the last paid invoice refunded" do
        before do
          @site = create(:site_with_invoice, plan_id: @paid_plan.id)
          @site.update_attribute(:refunded_at, Time.now.utc)
        end
        subject { @site.reload }

        it "returns nil" do
          subject.refunded_at.should be_present
          subject.last_paid_invoice.should be_nil
        end
      end
    end # #last_paid_invoice

    describe "#last_paid_plan" do
      context "site with no invoice" do
        subject { create(:site, plan_id: @free_plan.id) }

        its(:last_paid_plan) { should be_nil }
      end

      context "site with at least one paid invoice" do
        before do
          @plan1 = create(:plan, price: 10_000)
          @plan2 = create(:plan, price: 5_000)
          @site  = create(:site_with_invoice, plan_id: @plan1.id)
          @site.plan_id = @plan2.id
        end

        subject { @site }

        it "should return the plan of the last InvoiceItem::Plan with an price > 0" do
          subject.last_paid_plan.should eq @plan1
        end
      end
    end # #last_paid_plan

    describe "#last_paid_plan_price" do
      context "site with no invoice" do
        subject { create(:site, plan_id: @free_plan.id) }

        its(:last_paid_plan_price) { should eq 0 }
      end

      context "site with at least one paid invoice" do
        before do
          @plan1 = create(:plan, price: 10_000)
          @plan2 = create(:plan, price: 5_000)
          @site  = create(:site_with_invoice, plan_id: @plan1.id)
          @site.plan_id = @plan2.id
        end

        subject { @site }

        it "should return the price of the last InvoiceItem::Plan with an price > 0" do
          subject.last_paid_plan_price.should eq @plan1.price
        end
      end
    end # #last_paid_plan_price

    describe "#plan_month_cycle_started_at & #plan_month_cycle_ended_at" do
      context "with free plan" do
        subject { create(:site, plan_id: @free_plan.id) }

        its(:plan_month_cycle_started_at) { should eq (1.month - 1.day).ago.midnight }
        its(:plan_month_cycle_ended_at)   { should eq Time.now.utc.end_of_day }
      end

      context "with monthly plan in trial" do
        subject { create(:site) }

        its(:plan_month_cycle_started_at) { should eq (1.month - 1.day).ago.midnight }
        its(:plan_month_cycle_ended_at)   { should eq Time.now.utc.end_of_day }
      end

      context "with monthly plan" do
        subject { create(:site_not_in_trial) }

        its(:plan_month_cycle_started_at)     { should eq Time.now.utc.midnight }
        its("plan_month_cycle_ended_at.to_i") { should eq (Time.now.utc + 1.month - 1.day).end_of_day.to_i }
      end

      context "with yearly plan" do
        let(:yearly_plan) { create(:plan, cycle: 'year') }

        describe "before the first month" do
          subject { create(:site_not_in_trial, plan_id: yearly_plan.id) }

          its(:plan_month_cycle_started_at) { should eq Time.now.utc.midnight }
          its(:plan_month_cycle_ended_at)   { should eq (Time.now.utc + 1.month - 1.day).end_of_day }
        end

        describe "after the first month" do
          subject {
            Timecop.travel(35.days.ago) {
              @site = create(:site_not_in_trial, plan_id: yearly_plan.id)
            }
            @site
          }

          its(:plan_month_cycle_started_at) { should eq (35.days.ago + 1.month).utc.midnight }
          its(:plan_month_cycle_ended_at)   { should eq (35.days.ago + 2.months - 1.day).end_of_day }
        end
      end
    end

    describe "#trial_end" do
      before do
        @site_not_in_trial = create(:site, plan_id: @free_plan.id)
        @site_in_trial = create(:site)
      end

      specify { @site_not_in_trial.trial_end.should be_nil }
      specify { @site_in_trial.trial_end.should eq BusinessModel.days_for_trial.days.from_now.yesterday.end_of_day }
    end

    describe "#trial_expires_on & #trial_expires_in_less_than_or_equal_to", :plans do
      before do
        @site_not_in_trial = create(:site, plan_id: @free_plan.id)
        @site_in_trial = create(:site)
      end

      specify { @site_in_trial.trial_expires_on(BusinessModel.days_for_trial.days.from_now).should be_true }
      specify { @site_in_trial.trial_expires_in_less_than_or_equal_to(BusinessModel.days_for_trial.days.from_now - 1.day).should be_false }
      specify { @site_in_trial.trial_expires_in_less_than_or_equal_to(BusinessModel.days_for_trial.days.from_now).should be_true }
      specify { @site_in_trial.trial_expires_in_less_than_or_equal_to(BusinessModel.days_for_trial.days.from_now + 1.day).should be_true }
    end

    describe "#prepare_pending_attributes" do
      before(:all) do
        @paid_plan         = create(:plan, cycle: "month", price: 1000)
        @paid_plan2        = create(:plan, cycle: "month", price: 5000)
        @paid_plan_yearly  = create(:plan, cycle: "year",  price: 10000)
        @paid_plan_yearly2 = create(:plan, cycle: "year",  price: 50000)
      end
      # All plans deleted in spec/config/plans

      describe "new site" do
        context "with free plan" do
          before do
            @site = build(:new_site, plan_id: @free_plan.id)
            @site.prepare_pending_attributes
          end
          subject { @site }

          its(:pending_plan_started_at)       { should be_present }
          its(:pending_plan_cycle_started_at) { should be_nil }
          its(:pending_plan_cycle_ended_at)   { should be_nil }
          its(:plan)                          { should be_nil }
          its(:pending_plan)                  { should eq @free_plan }
          its(:next_cycle_plan)               { should be_nil }
          it { should_not be_instant_charging }
        end

        context "with monthly paid plan" do
          context "in trial" do
            before do
              @site = build(:new_site, plan_id: @paid_plan.id)
              @site.prepare_pending_attributes
            end
            subject { @site }

            its(:pending_plan_started_at)       { should be_present }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should be_nil }
            its(:pending_plan)                  { should eq @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_trial_ended }
            it { should_not be_instant_charging }
          end

          context "in trial with skip_trial == '0'" do
            before do
              @site = build(:new_site, plan_id: @paid_plan.id, skip_trial: '0')
              @site.prepare_pending_attributes
            end
            subject { @site }

            its(:pending_plan_started_at)       { should be_present }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should be_nil }
            its(:pending_plan)                  { should eq @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_trial_ended }
            it { should_not be_instant_charging }
          end

          context "in trial with skip_trial == '1'" do
            before do
              @site = build(:new_site, plan_id: @paid_plan.id, skip_trial: '1')
              @site.prepare_pending_attributes
            end
            subject { @site }

            its(:skip_trial)    { should eq '1' }
            its(:first_paid_plan_started_at)    { should be_present }
            its(:pending_plan_started_at)       { should be_present }
            its(:pending_plan_started_at)       { should be_present }
            its(:pending_plan_cycle_started_at) { should be_present }
            its(:pending_plan_cycle_ended_at)   { should be_present }
            its(:plan)                          { should be_nil }
            its(:pending_plan)                  { should eq @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should be_trial_ended }
            it { should be_instant_charging }
          end

          context "in trial with skip_trial == 1" do
            before do
              @site = build(:new_site, plan_id: @paid_plan.id, skip_trial: 1)
              @site.prepare_pending_attributes
            end
            subject { @site }

            its(:first_paid_plan_started_at)    { should be_present }
            its(:pending_plan_started_at)       { should be_present }
            its(:pending_plan_started_at)       { should be_present }
            its(:pending_plan_cycle_started_at) { should be_present }
            its(:pending_plan_cycle_ended_at)   { should be_present }
            its(:plan)                          { should be_nil }
            its(:pending_plan)                  { should eq @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should be_trial_ended }
            it { should be_instant_charging }
          end

          context "not in trial" do
            before do
              Timecop.travel(Time.utc(2011,1,30)) do
                @site = build(:new_site, plan_id: @paid_plan.id, trial_started_at: BusinessModel.days_for_trial.days.ago)
                @site.first_paid_plan_started_at = Time.now.utc
                @site.prepare_pending_attributes
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should eq Time.utc(2011,1,30) }
            its(:pending_plan_cycle_started_at) { should eq Time.utc(2011,1,30) }
            its(:pending_plan_cycle_ended_at)   { should eq Time.utc(2011,2,27).to_datetime.end_of_day }
            its(:plan)                          { should be_nil }
            its(:pending_plan)                  { should eq @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_instant_charging }
          end
        end

        context "with yearly paid plan" do
          context "in trial" do
            before do
              @site = build(:new_site, plan_id: @paid_plan_yearly.id)
              @site.prepare_pending_attributes
            end
            subject { @site }

            its(:pending_plan_started_at)       { should be_present }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should be_nil }
            its(:pending_plan)                  { should eq @paid_plan_yearly }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_instant_charging }
          end

          context "not in trial" do
            before do
              Timecop.travel(Time.utc(2011,1,30)) do
                @site = create(:new_site, plan_id: @paid_plan_yearly.id, trial_started_at: BusinessModel.days_for_trial.days.ago)
                @site.first_paid_plan_started_at = Time.now.utc
                @site.prepare_pending_attributes
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should eq Time.utc(2011,1,30) }
            its(:pending_plan_cycle_started_at) { should eq Time.utc(2011,1,30) }
            its(:pending_plan_cycle_ended_at)   { should eq Time.utc(2012,1,29).to_datetime.end_of_day }
            its(:plan)                          { should be_nil }
            its(:pending_plan)                  { should eq @paid_plan_yearly }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_instant_charging }
          end
        end
      end

      describe "upgrade site" do
        context "from free plan to paid plan" do
          context "in trial" do
            before do
              @site = create(:site, plan_id: @free_plan.id)
              @site.apply_pending_attributes
              @site.reload.plan_id = @paid_plan.id # upgrade
              Timecop.travel((BusinessModel.days_for_trial-1).days.from_now) { @site.prepare_pending_attributes }
            end
            subject { @site }

            its(:pending_plan_started_at)       { should eq (BusinessModel.days_for_trial-1).days.from_now.midnight }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should eq @free_plan }
            its(:pending_plan)                  { should eq @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_trial_ended }
            it { should_not be_instant_charging }
          end

          context "in trial with skip_trial == '1'" do
            before do
              @site = create(:site, plan_id: @free_plan.id)
              @site.apply_pending_attributes
              @site.reload.plan_id = @paid_plan.id # upgrade
              @site.skip_trial = '1'
              @site.prepare_pending_attributes
            end
            subject { @site }

            its(:pending_plan_started_at)       { should eq Time.now.utc.midnight }
            its(:pending_plan_cycle_started_at) { should be_present }
            its(:pending_plan_cycle_ended_at)   { should be_present }
            its(:plan)                          { should eq @free_plan }
            its(:pending_plan)                  { should eq @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should be_trial_ended }
            it { should be_instant_charging }
          end

          context "not in trial" do
            before do
              @site = create(:site_not_in_trial, plan_id: @free_plan.id, first_paid_plan_started_at: Time.now.utc)

              Timecop.travel(2.months.from_now) do
                @site.prepare_pending_attributes
                @site.apply_pending_attributes

                @site.reload.plan_id = @paid_plan.id # upgrade
                @site.prepare_pending_attributes
              end
            end
            subject { @site }

            it { subject.pending_plan_started_at.should       eq 2.months.from_now.midnight }
            it { subject.pending_plan_cycle_started_at.should eq subject.plan_cycle_started_at }
            it { subject.pending_plan_cycle_ended_at.should   eq subject.plan_cycle_ended_at }
            its(:plan)                          { should eq @free_plan }
            its(:pending_plan)                  { should eq @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should be_trial_ended }
            it { should be_instant_charging }
          end
        end

        context "from paid plan to paid plan" do
          context "in trial" do
            before do
              @site = create(:site, plan_id: @paid_plan.id)
              @site.reload.plan_id = @paid_plan2.id # upgrade
              Timecop.travel((BusinessModel.days_for_trial-1).days.from_now) { @site.prepare_pending_attributes }
            end
            subject { @site }

            its(:pending_plan_started_at)       { should eql (BusinessModel.days_for_trial-1).days.from_now.midnight }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should eql @paid_plan }
            its(:pending_plan)                  { should eql @paid_plan2 }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_trial_ended }
            it { should_not be_instant_charging }
          end

          context "not in trial" do
            before do
              @site = create(:site_with_invoice, plan_id: @paid_plan.id)
              Timecop.travel(2.months.from_now) do
                @site.prepare_pending_attributes
                @site.apply_pending_attributes

                @site.plan_id = @paid_plan2.id # upgrade
                @site.prepare_pending_attributes
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should eql 2.months.from_now.midnight }
            its(:pending_plan_cycle_started_at) { should eql 2.months.from_now.midnight }
            its(:pending_plan_cycle_ended_at)   { should eql (3.months.from_now - 1.day).to_datetime.end_of_day }
            its(:plan)                          { should eql @paid_plan }
            its(:pending_plan)                  { should eql @paid_plan2 }
            its(:next_cycle_plan)               { should be_nil }
            it { should be_trial_ended }
            it { should be_instant_charging }
          end
        end
      end

      describe "renew site" do
        context "without downgrade" do
          before do
            @site = create(:site_with_invoice, plan_id: @paid_plan.id)

            Timecop.travel(2.months.from_now) do
              @site.prepare_pending_attributes
            end
          end
          subject { @site }

          its(:pending_plan_started_at)       { should be_nil }
          its(:pending_plan_cycle_started_at) { should eql 2.months.from_now.midnight }
          its(:pending_plan_cycle_ended_at)   { should eql (3.months - 1.day).from_now.to_datetime.end_of_day }
          its(:plan)                          { should eql @paid_plan }
          its(:pending_plan)                  { should be_nil }
          its(:next_cycle_plan)               { should be_nil }
          it { should be_trial_ended }
          it { should_not be_instant_charging }
        end

        context "with downgrade" do
          context "from paid plan to free plan but during the pending cycle" do
            before do
              @site = create(:site_with_invoice, plan_id: @paid_plan.id)

              Timecop.travel(2.months.from_now) do
                @site.prepare_pending_attributes
                @site.apply_pending_attributes

                @site.plan_id = @free_plan.id
                @site.prepare_pending_attributes
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should be_nil }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should eql @paid_plan }
            its(:pending_plan)                  { should be_nil }
            its(:next_cycle_plan)               { should eql @free_plan }
            it { should be_trial_ended }
            it { should_not be_instant_charging }
          end

          context "from paid plan to free plan" do
            before do
              @site = create(:site_with_invoice, plan_id: @paid_plan.id)

              Timecop.travel(2.months.from_now) do
                @site.plan_id = @free_plan.id
                @site.prepare_pending_attributes
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should eql 1.month.from_now.midnight }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should eql @paid_plan }
            its(:pending_plan)                  { should eql @free_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should be_trial_ended }
            it { should_not be_instant_charging }
          end

          context "from paid plan to free plan but during the pending cycle" do
            before do
              @site = create(:site_with_invoice, plan_id: @paid_plan2.id)

              Timecop.travel(2.months.from_now) do
                @site.prepare_pending_attributes
                @site.apply_pending_attributes

                @site.plan_id = @paid_plan.id
                @site.prepare_pending_attributes
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should be_nil }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should eql @paid_plan2 }
            its(:pending_plan)                  { should be_nil }
            its(:next_cycle_plan)               { should eql @paid_plan }
            it { should be_trial_ended }
            it { should_not be_instant_charging }
          end

          context "from paid plan to paid plan" do
            before do
              @site = create(:site_with_invoice, plan_id: @paid_plan2.id)

              Timecop.travel(2.months.from_now) do
                @site.plan_id = @paid_plan.id
                @site.prepare_pending_attributes
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should eql 1.month.from_now.midnight }
            its(:pending_plan_cycle_started_at) { should eql (1.month.from_now.midnight + 1.month) }
            its(:pending_plan_cycle_ended_at)   { should eql (1.month.from_now.midnight + 2.months - 1.day).to_datetime.end_of_day }
            its(:plan)                          { should eql @paid_plan2 }
            its(:pending_plan)                  { should eql @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should be_trial_ended }
            it { should_not be_instant_charging }
          end
        end
      end
    end # #prepare_pending_attributes

    describe "#apply_pending_attributes" do
      before do
        @site = create(:site, plan_id: @free_plan.id)
        @site = Site.find(@site) # hard reset to plan association cache
        @site.pending_plan_id                           = @paid_plan.id
        @site.pending_plan_started_at                   = Time.utc(2012,12,21)
        @site.pending_plan_cycle_started_at             = Time.utc(2012,12,21)
        @site.pending_plan_cycle_ended_at               = Time.utc(2013,12,20)
        @site.first_plan_upgrade_required_alert_sent_at = Time.utc(2012,11,10)

        @site.apply_pending_attributes
      end
      subject { @site }

      it { should be_persisted }

      its(:first_plan_upgrade_required_alert_sent_at) { should be_nil }

      its(:plan_id)               { should == @paid_plan.id }
      its(:plan)                  { should == @paid_plan }
      its(:plan_started_at)       { should == Time.utc(2012,12,21) }
      its(:plan_cycle_started_at) { should == Time.utc(2012,12,21) }
      its(:plan_cycle_ended_at)   { should == Time.utc(2013,12,20).to_datetime.end_of_day }

      its(:pending_plan_id)               { should be_nil }
      its(:pending_plan)                  { should be_nil }
      its(:pending_plan_started_at)       { should be_nil }
      its(:pending_plan_cycle_started_at) { should be_nil }
      its(:pending_plan_cycle_ended_at)   { should be_nil }
    end # #apply_pending_attributes

    describe "#advance_for_next_cycle_end" do
      before do
        @site = build(:new_site, plan_id: @paid_plan.id)
        @site.prepare_pending_attributes
        @site.apply_pending_attributes
      end

      context "with a monthly plan" do
        before { @plan = create(:plan, cycle: "month") }

        context "when now is less than 1 month after site.plan_started_at" do
          it "should return 0 year + 1 month in advance - 1 day" do
            Timecop.travel(Time.now.utc.midnight + 1.day) do
              @site.send(:advance_for_next_cycle_end, @plan).should == 1.month - 1.day
            end
          end
        end

        context "when now is 2 months after start time" do
          it "should return 3 month in advance - 1 day" do
            Timecop.travel(Time.now.utc.midnight + 1.day) do
              @site.send(:advance_for_next_cycle_end, @plan, 2.month.ago).should == 3.months - 1.day
            end
          end
        end

        1.upto(13) do |i|
          context "when now is #{i} months after site.plan_started_at" do
            it "should return #{i+1} months in advance - 1 day" do
              Timecop.travel(Time.now.utc.midnight + i.months + 1.day) do
                @site.send(:advance_for_next_cycle_end, @plan).should == (i + 1).months - 1.day
              end
            end
          end
        end
      end

      context "with a yearly plan" do
        before { @plan = create(:plan, cycle: "year") }

        context "when now is less than 1 yearly after site.plan_started_at" do
          it "should return 12 months in advance - 1 day" do
            Timecop.travel(Time.now.utc.midnight + 1.day) do
              @site.send(:advance_for_next_cycle_end, @plan).should == 12.months - 1.day
            end
          end
        end

        context "when now is more than 1 year after site.plan_started_at" do
          1.upto(3) do |i|
            it "should return #{i*12 + 12} months in advance - 1 day" do
              Timecop.travel(Time.now.utc.midnight + i.years + 1.day) do
                @site.send(:advance_for_next_cycle_end, @plan).should == (i*12 + 12).months - 1.day
              end
            end
          end
        end
      end
    end # #advance_for_next_cycle_end

    describe "#activated?" do
      it { build(:site_not_in_trial, plan_id: @free_plan.id).should_not be_activated }
      it { build(:site_not_in_trial, plan_id: @paid_plan.id).should_not be_activated }
      it do
        site = build(:site_not_in_trial)
        site.sponsor!
        site.should_not be_activated
      end

      describe "activation" do
        subject do
          site = build(:site_not_in_trial)
          site.first_paid_plan_started_at = Time.now.utc
          site
        end

        it { should be_activated }
      end
    end

    describe "#upgraded?" do
      it { build(:site_not_in_trial, plan_id: @free_plan.id).should_not be_upgraded }
      it { build(:site_not_in_trial, plan_id: @paid_plan.id).should_not be_upgraded }
      it do
        site = build(:site_not_in_trial)
        site.sponsor!
        site.should_not be_upgraded
      end

      describe "activation" do
        subject do
          site = build(:site_not_in_trial)
          site.first_paid_plan_started_at = Time.now.utc
          site
        end

        it { should_not be_upgraded }
      end

      describe "normal renew" do
        subject do
          site = build(:site_not_in_trial)
          site.pending_plan_cycle_started_at = Time.now.utc
          site
        end

        it { should_not be_upgraded }
      end

      describe "downgrade" do
        subject do
          site = build(:site_not_in_trial, plan_id: @custom_plan.token)
          site.plan_id = @paid_plan.id
          site.pending_plan_cycle_started_at = Time.now.utc
          site
        end

        it { should_not be_upgraded }
      end

      describe "upgrade" do
        subject do
          site = build(:site_not_in_trial, plan_id: @paid_plan.id)
          site.plan_id = @custom_plan.token
          site
        end

        it { should be_upgraded }
      end
    end

    describe "#renewed?" do
      it { build(:site_not_in_trial, plan_id: @free_plan.id).should_not be_renewed }
      it { build(:site_not_in_trial, plan_id: @paid_plan.id).should_not be_renewed }
      it do
        site = build(:site_not_in_trial)
        site.sponsor!
        site.should_not be_renewed
      end

      describe "activation" do
        subject do
          site = build(:site_not_in_trial)
          site.first_paid_plan_started_at    = Time.now.utc
          site.pending_plan_cycle_started_at = Time.now.utc
          site
        end

        it { should_not be_renewed }
      end

      describe "no plan change but pending_plan_cycle_started_at is set to nil" do
        subject do
          site = create(:site_not_in_trial, plan_id: @custom_plan.token)
          site.update_attribute(:pending_plan_cycle_started_at, Time.now.utc)
          site.pending_plan_cycle_started_at = nil
          site
        end

        it { should_not be_renewed }
      end

      describe "normal renew" do
        subject do
          site = build(:site_not_in_trial, plan_id: @custom_plan.token)
          site.pending_plan_cycle_started_at = Time.now.utc
          site
        end

        it { should be_renewed }
      end

      describe "downgrade" do
        subject do
          site = build(:site_not_in_trial, plan_id: @custom_plan.token)
          site.plan_id = @paid_plan.id
          site.pending_plan_cycle_started_at = Time.now.utc
          site
        end

        it { should be_renewed }
      end

      describe "upgrade" do
        subject do
          site = build(:site_not_in_trial, plan_id: @paid_plan.id)
          site.plan_id = @custom_plan.token
          site.pending_plan_cycle_started_at = Time.now.utc
          site
        end

        it { should_not be_renewed }
      end
    end

    describe "#create_and_charge_invoice" do
      before(:all) do
        @paid_plan         = create(:plan, cycle: "month", price: 1000)
        @paid_plan2        = create(:plan, cycle: "month", price: 5000)
        @paid_plan_yearly  = create(:plan, cycle: "year",  price: 10000)
        @paid_plan_yearly2 = create(:plan, cycle: "year",  price: 50000)
      end
      # All plans deleted in spec/config/plans

      context "site in free plan" do
        context "on creation" do
          subject { build(:new_site, plan_id: @free_plan.id) }

          it "doesn't create an invoice" do
            expect { subject.save! }.to_not change(subject.invoices, :count)
            subject.reload.plan.should == @free_plan
          end
        end

        context "on a saved record" do
          before { @site = create(:site, plan_id: @free_plan.id) }

          describe "save with no changes" do
            subject { @site.reload }

            it "doesn't create an invoice" do
              expect { Timecop.travel(3.months.from_now) { subject.save! } }.to_not change(subject.invoices, :count)
              subject.reload.plan.should == @free_plan
            end
          end

          describe "upgrade" do
            subject { @site.reload }

            it "doesn't create an invoice" do
              subject.plan_id = @paid_plan.id
              subject.user_attributes = { current_password: "123456" }
              expect { Timecop.travel(3.months.from_now) { subject.save! } }.to_not change(subject.invoices, :count)
              subject.reload.plan.should == @paid_plan
            end
          end

          describe "suspend" do
            subject { @site.reload }

            it "doesn't create and not try to charge the invoice" do
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.suspend! }.to_not change(subject.invoices, :count) }
              subject.should be_suspended
            end
          end

          describe "archive" do
            subject { @site.reload }

            it "doesn't create an invoice" do
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.archive! }.to_not change(subject.invoices, :count) }
              subject.should be_archived
            end
          end
        end
      end # context "site in free plan"

      context "site in paid plan" do
        context "on creation" do
          subject { build(:site, plan_id: @paid_plan2.id) }

          it "doesn't create an invoice" do
            expect { subject.save! }.to_not change(subject.invoices, :count).by(1)
          end
        end

        context "on a saved record" do
          subject do
            @site.reload
            @site.user_attributes = { "current_password" => "123456" }
            @site
          end

          context "in trial" do
            before do
              @site = create(:site, plan_id: @paid_plan2.id)
              subject.should be_trial_not_started_or_in_trial
            end

            describe "upgrade" do
              it "doesn't create an invoice" do
                subject.plan_id = @paid_plan_yearly.id
                expect { subject.save! }.to_not change(subject.invoices, :count)
              end
            end

            describe "downgrade" do
              it "doesn't create an invoice" do
                subject.plan_id = @free_plan.id
                expect { subject.save! }.to_not change(subject.invoices, :count)
              end
            end

            %w[save suspend archive].each do |action|
              describe "#{action}" do
                it "doesn't create an invoice" do
                  expect { subject.send "#{action}!" }.to_not change(subject.invoices, :count)
                end
              end
            end
          end

          context "not in trial, during first cycle" do
            before { @site = create(:site_with_invoice, plan_id: @paid_plan2.id) }

            describe "save with no changes" do
              it "doesn't create an invoice" do
                subject.prepare_pending_attributes
                expect { subject.save! }.to_not change(subject.invoices, :count)
              end
            end

            describe "save with first_paid_plan_started_at changed" do
              it "doesn't create an invoice" do
                subject.first_paid_plan_started_at = Time.now
                subject.prepare_pending_attributes
                expect { subject.save! }.to_not change(subject.invoices, :count)
              end
            end
          end

          context "not in trial, during second cycle" do
            before do
              @site = create(:site_with_invoice, plan_id: @paid_plan2.id, first_paid_plan_started_at: Time.now.utc)
              Timecop.travel(45.days.from_now)
            end
            after { Timecop.return }

            describe "renew" do
              it "creates an invoice" do
                subject.prepare_pending_attributes
                expect { subject.save! }.to change(subject.invoices, :count).by(1)
              end
            end

            describe "upgrade" do
              subject do
                @site = create(:site_with_invoice, plan_id: @paid_plan2.id)
                @site.reload
                @site.user_attributes = { "current_password" => "123456" }
                @site
              end

              it "creates an invoice, and one only" do
                subject.plan_id = @paid_plan_yearly2.id
                expect { subject.save! }.to change(subject.invoices, :count).by(1)
                expect { subject.save! }.to_not change(subject.invoices, :count)
              end
            end

            describe "downgrade" do
              it "to free plan, doesn't create an invoice" do
                subject.plan_id = @free_plan.id
                expect { subject.save! }.to_not change(subject.invoices, :count)
              end

              it "to paid plan, doesn't create an invoice" do
                subject.plan_id = @paid_plan.id
                expect { subject.save! }.to_not change(subject.invoices, :count)
              end

              it "to paid plan, create an invoice once cycle ends" do
                subject.plan_id = @paid_plan.id
                subject.save!
                Timecop.return
                Timecop.travel(31.days.from_now)
                subject.prepare_pending_attributes # simulate renew
                expect { subject.save! }.to change(subject.invoices, :count).by(1)
              end
            end

            %w[suspend archive].each do |action|
              describe "#{action}" do
                it "doesn't create an invoice" do
                  expect { subject.send "#{action}!" }.to_not change(subject.invoices, :count)
                end
              end
            end
          end
        end
      end # context "site in paid plan"

    end # #create_and_charge_invoice

    describe "#months_since" do
      before { @site = create(:site) }

      context "with plan_started_at 2011,1,1" do
        before { @site.plan_started_at = Time.utc(2011,1,1) }

        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.months_since(nil).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.months_since(@site.plan_started_at).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,1,31)) { @site.months_since(@site.plan_started_at).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,2,1))  { @site.months_since(@site.plan_started_at).should eq 1 } }
        specify { Timecop.travel(Time.utc(2011,2,15)) { @site.months_since(@site.plan_started_at).should eq 1 } }
        specify { Timecop.travel(Time.utc(2011,2,28)) { @site.months_since(@site.plan_started_at).should eq 1 } }
        specify { Timecop.travel(Time.utc(2012,1,1))  { @site.months_since(@site.plan_started_at).should eq 12 } }
        specify { Timecop.travel(Time.utc(2013,1,15)) { @site.months_since(@site.plan_started_at).should eq 24 } }
      end

      context "with plan_started_at 2011,6,15" do
        before { @site.plan_started_at = Time.utc(2011,6,15) }

        specify { Timecop.travel(Time.utc(2011,6,20)) { @site.months_since(nil).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,6,20)) { @site.months_since(@site.plan_started_at).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,6,31)) { @site.months_since(@site.plan_started_at).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,7,10)) { @site.months_since(@site.plan_started_at).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,7,15)) { @site.months_since(@site.plan_started_at).should eq 1 } }
        specify { Timecop.travel(Time.utc(2011,7,25)) { @site.months_since(@site.plan_started_at).should eq 1 } }
        specify { Timecop.travel(Time.utc(2012,6,10)) { @site.months_since(@site.plan_started_at).should eq 11 } }
        specify { Timecop.travel(Time.utc(2012,6,15)) { @site.months_since(@site.plan_started_at).should eq 12 } }
        specify { Timecop.travel(Time.utc(2012,6,20)) { @site.months_since(@site.plan_started_at).should eq 12 } }
        specify { Timecop.travel(Time.utc(2012,6,25)) { @site.months_since(@site.plan_started_at).should eq 12 } }
      end

      context "with plan_started_at 2011,6,30" do
        before { @site.plan_started_at = Time.utc(2011,6,30) }

        specify { Timecop.travel(Time.utc(2011,7,20)) { @site.months_since(nil).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,7,20)) { @site.months_since(@site.plan_started_at).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,7,31)) { @site.months_since(@site.plan_started_at).should eq 1 } }
        specify { Timecop.travel(Time.utc(2011,8,15)) { @site.months_since(@site.plan_started_at).should eq 1 } }
        specify { Timecop.travel(Time.utc(2011,8,30)) { @site.months_since(@site.plan_started_at).should eq 2 } }
        specify { Timecop.travel(Time.utc(2012,2,29)) { @site.months_since(@site.plan_started_at).should eq 8 } }
      end
    end

    describe "#days_since" do
      before { @site = create(:site) }

      context "with first_paid_plan_started_at 2011,1,1" do
        before { @site.first_paid_plan_started_at = Time.utc(2011,1,1) }

        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.days_since(nil).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.days_since(@site.first_paid_plan_started_at).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,1,31)) { @site.days_since(@site.first_paid_plan_started_at).should == 30 } }
        specify { Timecop.travel(Time.utc(2011,2,1))  { @site.days_since(@site.first_paid_plan_started_at).should == 31 } }
        specify { Timecop.travel(Time.utc(2011,2,28)) { @site.days_since(@site.first_paid_plan_started_at).should == 58 } }
        specify { Timecop.travel(Time.utc(2011,3,1))  { @site.days_since(@site.first_paid_plan_started_at).should == 59 } }
        specify { Timecop.travel(Time.utc(2012,3,1))  { @site.days_since(@site.first_paid_plan_started_at).should == 425 } }
        specify { Timecop.travel(Time.utc(2012,1,1))  { @site.days_since(@site.first_paid_plan_started_at).should == 365 } }
        specify { Timecop.travel(Time.utc(2013,1,1))  { @site.days_since(@site.first_paid_plan_started_at).should == 731 } }
      end
    end

    describe "#set_trial_started_at" do
      it "set if site created with free plan" do
        site = create(:site, plan_id: @free_plan.id)
        site.trial_started_at.should be_nil
      end

      it "set if site created with paid plan" do
        site = create(:site, plan_id: @paid_plan.id)
        site.trial_started_at.should be_present
      end

      it "not reset on downgrade" do
        site = create(:site, plan_id: @paid_plan.id)
        site.trial_started_at.should be_present

        first_trial_started_at = site.trial_started_at
        site.update_attribute(:plan_id, @free_plan.id)
        site.reload.trial_started_at.should eq first_trial_started_at
      end

      it "not reset on upgrade" do
        @foo_plan = create(:plan, name: "premium", video_views: 1_000_000)
        site = create(:site_with_invoice, plan_id: @paid_plan.id)
        site.trial_started_at.should be_present

        first_trial_started_at = site.trial_started_at
        site.update_attribute(:plan_id, @foo_plan.id)
        site.reload.trial_started_at.should eq first_trial_started_at
      end

      it "not reset if site created with paid plan and downgraded to free plan and reupgraded to paid plan" do
        site = create(:site, plan_id: @paid_plan.id)
        site.trial_started_at.should be_present

        first_trial_started_at = site.trial_started_at
        site.update_attribute(:plan_id, @free_plan.id)
        site.reload.trial_started_at.should eq first_trial_started_at

        site.update_attribute(:plan_id, @paid_plan.id)
        site.reload.trial_started_at.should eq first_trial_started_at
      end
    end

    describe "#set_first_paid_plan_started_at" do
      context "site in trial" do
        it "set if site created with free plan" do
          site = create(:site, plan_id: @free_plan.id)
          site.first_paid_plan_started_at.should be_nil
        end

        it "set if site created with paid plan" do
          site = create(:site, plan_id: @paid_plan.id)
          site.first_paid_plan_started_at.should be_nil
        end

        it "not set on downgrade" do
          site = create(:site, plan_id: @paid_plan.id)
          site.first_paid_plan_started_at.should be_nil

          site.update_attribute(:plan_id, @free_plan.id)
          site.reload.first_paid_plan_started_at.should be_nil
        end

        it "not set on upgrade" do
          @foo_plan = create(:plan, name: "premium", video_views: 1_000_000)
          site = create(:site, plan_id: @paid_plan.id)
          site.first_paid_plan_started_at.should be_nil

          site.update_attribute(:plan_id, @foo_plan.id)
          site.reload.first_paid_plan_started_at.should be_nil
        end

        it "not reset if site created with paid plan and downgraded to free plan and reupgraded to paid plan" do
          site = create(:site, plan_id: @paid_plan.id)
          site.first_paid_plan_started_at.should be_nil

          site.update_attribute(:plan_id, @free_plan.id)
          site.reload.first_paid_plan_started_at.should be_nil

          site.update_attribute(:plan_id, @paid_plan.id)
          site.reload.first_paid_plan_started_at.should be_nil
        end
      end

      context "site not in trial" do
        it "set if site created with free plan" do
          site = create(:new_site, plan_id: @free_plan.id, trial_started_at: BusinessModel.days_for_trial.days.ago)
          site.first_paid_plan_started_at.should be_nil
        end

        it "set if site created with paid plan" do
          site = create(:new_site, plan_id: @paid_plan.id, trial_started_at: BusinessModel.days_for_trial.days.ago)
          site.first_paid_plan_started_at.should be_present
        end

        it "not reset on downgrade" do
          site = create(:new_site, plan_id: @paid_plan.id, trial_started_at: BusinessModel.days_for_trial.days.ago)
          site.first_paid_plan_started_at.should be_present

          first_first_paid_plan_started_at = site.first_paid_plan_started_at
          site.update_attribute(:plan_id, @free_plan.id)
          site.reload.first_paid_plan_started_at.should eq first_first_paid_plan_started_at
        end

        it "not set on upgrade" do
          @foo_plan = create(:plan, name: "premium", video_views: 1_000_000)
          site = create(:new_site, plan_id: @paid_plan.id, trial_started_at: BusinessModel.days_for_trial.days.ago)
          site.first_paid_plan_started_at.should be_present

          first_first_paid_plan_started_at = site.first_paid_plan_started_at
          site.update_attribute(:plan_id, @foo_plan.id)
          site.reload.first_paid_plan_started_at.should eq first_first_paid_plan_started_at
        end

        it "not reset if site created with paid plan and downgraded to free plan and reupgraded to paid plan" do
          site = create(:new_site, plan_id: @paid_plan.id, trial_started_at: BusinessModel.days_for_trial.days.ago)
          site.first_paid_plan_started_at.should be_present

          first_first_paid_plan_started_at = site.first_paid_plan_started_at
          site.update_attribute(:plan_id, @free_plan.id)
          site.reload.first_paid_plan_started_at.should eq first_first_paid_plan_started_at

          site.update_attribute(:plan_id, @paid_plan.id)
          site.reload.first_paid_plan_started_at.should eq first_first_paid_plan_started_at
        end
      end

    end

  end # Instance Methods

end
