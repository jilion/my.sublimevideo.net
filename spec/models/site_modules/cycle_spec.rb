require 'spec_helper'

describe SiteModules::Cycle do
  describe 'Class Methods' do

    describe '.send_trial_will_expire_email', :plans do
      before do
        @user = create(:user_no_cc)
        @sites_wont_receive_email = [create(:site)]
        @sites_will_receive_email = []

        @sites_wont_receive_email << create(:site, user: @user, plan_id: @paid_plan.id).tap { |s| s.skip_password(:archive!) }

        BusinessModel.days_before_trial_end.each do |days_before_trial_end|
          Timecop.travel((BusinessModel.days_for_trial - days_before_trial_end).days.ago) do
            @sites_will_receive_email << create(:site, user: @user, plan_id: @trial_plan.id)
          end
        end
      end

      it "sends 'trial will end' email" do
        ActionMailer::Base.deliveries.clear
        expect { Site.send_trial_will_expire_email }.to change(Delayed::Job.where{ handler =~ '%Class%trial_will_expire%' }, :count).by(@sites_will_receive_email.size)
      end

      context "when we move 2 days in the future" do
        it "doesn't send 'trial will end' email" do
          ActionMailer::Base.deliveries.clear
          Timecop.travel(2.days.from_now) do
            expect { Site.send_trial_will_expire_email }.to_not change(Delayed::Job.where{ handler =~ '%Class%trial_will_expire%' }, :count)
          end
        end
      end
    end

    describe '.downgrade_sites_leaving_trial', :plans do
      let(:site) { create(:site, plan_id: @trial_plan.id) }

      context 'site with trial ended' do
        it 'downgrades to the Free plan' do
          site.should be_in_trial_plan

          Timecop.travel((BusinessModel.days_for_trial).days.from_now) { Site.downgrade_sites_leaving_trial }

          site.reload.should be_in_free_plan
        end
      end

      context 'site with trial not ended' do
        it 'dont downgrade to the Free plan' do
          site.should be_in_trial_plan

          Timecop.travel((BusinessModel.days_for_trial - 1).days.from_now) { Site.downgrade_sites_leaving_trial }

          site.reload.should be_in_trial_plan
        end
      end
    end # .downgrade_sites_leaving_trial

    describe '.renew_active_sites', :plans do
      before do
        Timecop.travel(2.months.ago) do
          @site_renewable = create(:site_with_invoice)
          @site_renewable_with_downgrade_to_free_plan = create(:site_with_invoice)
          @site_renewable_with_downgrade_to_free_plan.update_column(:next_cycle_plan_id, @free_plan.id)
          @site_renewable_with_downgrade_to_paid_plan = create(:site_with_invoice, plan_id: @custom_plan.token)
          @site_renewable_with_downgrade_to_paid_plan.update_column(:next_cycle_plan_id, @paid_plan.id)
          @site_in_trial = create(:site, plan_id: @trial_plan.id)
        end
        @site_not_renewable = create(:site_with_invoice, plan_started_at: 3.months.ago, plan_cycle_ended_at: 2.months.from_now)

        @site_renewable.invoices.paid.should have(1).item
        @site_renewable_with_downgrade_to_free_plan.invoices.paid.should have(1).item
        @site_renewable_with_downgrade_to_paid_plan.invoices.paid.should have(1).item
        @site_in_trial.reload.invoices.should have(0).items
        @site_not_renewable.invoices.paid.should have(1).item

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
        @site_renewable_with_downgrade_to_free_plan.reload.invoices.should have(1).items
        @site_in_trial.reload.invoices.should have(0).items
        @site_not_renewable.reload.invoices.should have(1).items

        @site_renewable.reload.invoices.should have(2).items
        @site_renewable_with_downgrade_to_paid_plan.reload.invoices.should have(2).items
      end

      it "updates plan cycle dates for renewable sites only" do
        [@site_not_renewable, @site_in_trial, @site_renewable_with_downgrade_to_free_plan].each do |site|
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
        @site_renewable_with_downgrade_to_free_plan.plan_id.should eq @free_plan.id

        @site_renewable_with_downgrade_to_paid_plan.reload.next_cycle_plan_id.should be_nil
        @site_renewable_with_downgrade_to_paid_plan.pending_plan_id.should eq @paid_plan.id
      end

      it "sets the renew flag to true" do
        @site_renewable_with_downgrade_to_free_plan.reload.invoices.by_date('asc').last.should_not be_renew
        @site_not_renewable.reload.invoices.by_date('asc').last.should_not be_renew

        @site_renewable.reload.invoices.by_date('asc').last.should be_renew
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

          subject.send(attr).should eq Time.now.utc.midnight
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

        subject.pending_plan_cycle_ended_at.should eq Time.now.utc.end_of_day
      end
    end # #pending_plan_cycle_ended_at=

    describe "#in_trial_plan?" do
      subject { create(:site, plan_id: @trial_plan.id) }

      it { should be_in_trial_plan }
    end # #in_trial_plan?

    describe "#in_free_plan?" do
      subject { create(:site, plan_id: @free_plan.id) }

      it { should be_in_free_plan }
    end # #in_free_plan?

    describe "#in_sponsored_plan?" do
      subject { site = create(:site); site.sponsor!; site.reload }

      it { should be_in_sponsored_plan }
    end # #in_sponsored_plan?

    describe "#in_paid_plan?" do
      context "trial plan" do
        subject { create(:site, plan_id: @trial_plan.id) }
        it { should_not be_in_paid_plan }
      end
      context "free plan" do
        subject { create(:site, plan_id: @free_plan.id) }
        it { should_not be_in_paid_plan }
      end
      context "standard plan" do
        subject { create(:site, plan_id: @paid_plan.id) }
        it { should be_in_paid_plan }
      end
      context "custom plan" do
        subject { create(:site, plan_id: @custom_plan.token) }
        it { should be_in_paid_plan }
      end
    end # #in_paid_plan?

    describe "#in_unpaid_plan?" do
      context "trial plan" do
        subject { create(:site, plan_id: @trial_plan.id) }
        it { should be_in_unpaid_plan }
      end
      context "free plan" do
        subject { create(:site, plan_id: @free_plan.id) }
        it { should be_in_unpaid_plan }
      end
      context "standard plan" do
        subject { create(:site, plan_id: @paid_plan.id) }
        it { should_not be_in_unpaid_plan }
      end
      context "custom plan" do
        subject { create(:site, plan_id: @custom_plan.token) }
        it { should_not be_in_unpaid_plan }
      end
    end # #in_unpaid_plan?

    describe "#trial_ended?" do
      before do
        @site_in_trial1 = create(:site, plan_id: @trial_plan.id)
        Timecop.travel((BusinessModel.days_for_trial-1).days.ago) { @site_in_trial2 = create(:site, plan_id: @trial_plan.id) }
        Timecop.travel((BusinessModel.days_for_trial+1).days.ago) { @site_not_in_trial = create(:site, plan_id: @trial_plan.id) }
      end

      specify { @site_in_trial1.should_not be_trial_ended }
      specify { @site_in_trial2.should_not be_trial_ended }
      specify { @site_not_in_trial.should be_trial_ended }
    end # #trial_ended?

    describe '#plan_month_cycle_started_at & #plan_month_cycle_ended_at' do
      context 'free plan' do
        subject { create(:site, plan_id: @free_plan.id) }

        its(:plan_month_cycle_started_at) { should eq (1.month - 1.day).ago.midnight }
        its(:plan_month_cycle_ended_at)   { should eq Time.now.utc.end_of_day }
      end

      context "with monthly plan" do
        subject { create(:site) }

        its(:plan_month_cycle_started_at)     { should eq Time.now.utc.midnight }
        its('plan_month_cycle_ended_at.to_i') { should eq (Time.now.utc + 1.month - 1.day).end_of_day.in_time_zone.to_i }
      end

      context "with yearly plan" do
        let(:yearly_plan) { create(:plan, cycle: 'year') }

        describe "before the first month" do
          subject { create(:site, plan_id: yearly_plan.id) }

          its(:plan_month_cycle_started_at) { should eq Time.now.utc.midnight }
          its(:plan_month_cycle_ended_at)   { should eq (Time.now.utc + 1.month - 1.day).end_of_day }
        end

        describe "after the first month" do
          subject {
            Timecop.travel(35.days.ago) {
              @site = create(:site, plan_id: yearly_plan.id)
            }
            @site
          }

          its(:plan_month_cycle_started_at) { should eq (35.days.ago + 1.month).utc.midnight }
          its(:plan_month_cycle_ended_at)   { should eq (35.days.ago + 2.months - 1.day).end_of_day }
        end
      end
    end # #plan_month_cycle_started_at & #plan_month_cycle_ended_at

    describe "#trial_end" do
      before do
        @site_not_in_trial = create(:site, plan_id: @free_plan.id)
        @site_in_trial     = create(:site, plan_id: @trial_plan.id)
      end

      specify { @site_not_in_trial.trial_end.should be_nil }
      specify { @site_in_trial.trial_end.should eq BusinessModel.days_for_trial.days.from_now.yesterday.end_of_day }
    end # #trial_end

    describe "#trial_expires_on & #trial_expires_in_less_than_or_equal_to", :plans do
      before do
        @site_not_in_trial = create(:site, plan_id: @free_plan.id)
        @site_in_trial     = create(:site, plan_id: @trial_plan.id)
      end

      specify { @site_not_in_trial.trial_expires_on(BusinessModel.days_for_trial.days.from_now).should be_false }
      specify { @site_in_trial.trial_expires_on(BusinessModel.days_for_trial.days.from_now).should be_true }
      specify { @site_in_trial.trial_expires_in_less_than_or_equal_to(BusinessModel.days_for_trial.days.from_now - 1.day).should be_false }
      specify { @site_in_trial.trial_expires_in_less_than_or_equal_to(BusinessModel.days_for_trial.days.from_now).should be_true }
      specify { @site_in_trial.trial_expires_in_less_than_or_equal_to(BusinessModel.days_for_trial.days.from_now + 1.day).should be_true }
    end # #trial_expires_on & #trial_expires_in_less_than_or_equal_to

    describe '#set_pending_plan_from_next_plan' do
      context 'new site in free' do
        let(:site) { build(:new_site, plan_id: @free_plan.id) }
        subject { site }
        before do
          site.set_pending_plan_from_next_plan
        end

        its(:pending_plan_id)    { should eq @free_plan.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      context 'new site in paid' do
        let(:site) { build(:new_site, plan_id: @paid_plan.id) }
        subject { site }
        before do
          site.set_pending_plan_from_next_plan
        end

        its(:pending_plan_id)    { should eq @paid_plan.id }
        its(:next_cycle_plan_id) { should be_nil }
      end

      context 'persisted site' do
        let(:site) { create(:site, plan_id: @paid_plan.id) }
        subject { site }

        context 'normal state' do
          before do
            site.set_pending_plan_from_next_plan
          end

          its(:pending_plan_id)    { should be_nil }
          its(:next_cycle_plan_id) { should be_nil }
        end

        context 'upgrade' do
          before do
            site.pending_plan_id = @custom_plan.id
            site.set_pending_plan_from_next_plan
          end

          its(:pending_plan_id)    { should eq @custom_plan.id }
          its(:next_cycle_plan_id) { should be_nil }
        end

        context 'will downgrade to paid' do
          let(:site) { create(:site, plan_id: @custom_plan.token) }
          before do
            site.next_cycle_plan_id = @paid_plan.id
            site.set_pending_plan_from_next_plan
          end

          its(:pending_plan_id)    { should be_nil }
          its(:next_cycle_plan_id) { should eq @paid_plan.id }
        end

        context 'will downgrade to free' do
          before do
            site.next_cycle_plan_id = @free_plan.id
            site.set_pending_plan_from_next_plan
          end

          its(:pending_plan_id)    { should be_nil }
          its(:next_cycle_plan_id) { should eq @free_plan.id }
        end

        context 'renew' do
          context 'normal state' do
            before do
              Timecop.travel(1.month.from_now) { site.set_pending_plan_from_next_plan }
            end

            its(:pending_plan_id)    { should be_nil }
            its(:next_cycle_plan_id) { should be_nil }
          end

          context 'with downgrade' do
            before do
              site.next_cycle_plan_id = @free_plan.id
              Timecop.travel(1.month.from_now) { site.set_pending_plan_from_next_plan }
            end

            its(:pending_plan_id)    { should eq @free_plan.id }
            its(:next_cycle_plan_id) { should be_nil }
          end
        end
      end
    end # #set_pending_plan_from_next_plan

    describe '#set_pending_plan_started_at' do
      context 'new site in free' do
        let(:site) { build(:new_site, plan_id: @free_plan.id) }
        subject { site }
        before do
          site.set_pending_plan_started_at
        end

        its(:pending_plan_started_at) { should eq Time.now.utc.midnight }
      end

      context 'new site in paid' do
        let(:site) { build(:new_site, plan_id: @paid_plan.id) }
        subject { site }
        before do
          site.set_pending_plan_started_at
        end

        its(:pending_plan_started_at) { should eq Time.now.utc.midnight }
      end

      context 'persisted site' do
        let(:site) { create(:site, plan_id: @paid_plan.id) }
        subject { site }

        context 'normal state' do
          before do
            Timecop.travel(2.days.from_now) { site.set_pending_plan_started_at }
          end

          its(:pending_plan_started_at) { should be_nil }
        end

        context 'upgrade' do
          before do
            site.pending_plan_id = @custom_plan.id
            Timecop.travel(2.days.from_now) { site.set_pending_plan_started_at }
          end

          its(:pending_plan_started_at) { should eq Time.now.utc.midnight }
        end

        context 'will downgrade to paid' do
          let(:site) { create(:site, plan_id: @custom_plan.token) }
          before do
            site.next_cycle_plan_id = @paid_plan.id
            Timecop.travel(2.days.from_now) { site.set_pending_plan_started_at }
          end

          its(:pending_plan_started_at) { should be_nil }
        end

        context 'will downgrade to free' do
          before do
            site.next_cycle_plan_id = @free_plan.id
            Timecop.travel(2.days.from_now) { site.set_pending_plan_started_at }
          end

          its(:pending_plan_started_at) { should be_nil }
        end

        context 'renew' do
          context 'normal state' do
            before do
              Timecop.travel(1.month.from_now) { site.set_pending_plan_started_at }
            end

            its(:pending_plan_started_at) { should be_nil }
          end

          context 'with downgrade' do
            before do
              site.pending_plan_id = @free_plan.id
              Timecop.travel(1.month.from_now) { site.set_pending_plan_started_at }
            end

            its(:pending_plan_started_at) { should eq site.plan_cycle_ended_at.tomorrow.midnight }
          end
        end
      end
    end # #set_pending_plan_started_at

    describe '#set_pending_plan_cycle_dates' do
      context 'new site in free' do
        let(:site) { build(:new_site, plan_id: @free_plan.id) }
        subject { site }
        before do
          site.set_pending_plan_cycle_dates
        end

        its(:pending_plan_cycle_started_at) { should be_nil }
        its(:pending_plan_cycle_ended_at)   { should be_nil }
      end

      context 'new site in paid' do
        let(:site) { build(:new_site, plan_id: @paid_plan.id) }
        subject { site }
        before do
          site.set_pending_plan_started_at
          site.set_pending_plan_cycle_dates
        end

        its(:pending_plan_cycle_started_at)     { should eq Time.now.utc.midnight }
        its('pending_plan_cycle_ended_at.to_i') { should eq 1.month.from_now.yesterday.end_of_day.to_i }
      end

      context 'persisted site' do
        let(:site) { create(:site, plan_id: @paid_plan.id) }
        subject { site }

        context 'normal state' do
          before do
            site # eager loading!
            Timecop.travel(2.days.from_now) { site.set_pending_plan_cycle_dates }
          end

          its(:pending_plan_cycle_started_at) { should be_nil }
          its(:pending_plan_cycle_ended_at)   { should be_nil }
        end

        context 'upgrade' do
          before do
            site.pending_plan_id = @custom_plan.id
            Timecop.travel(2.days.from_now) { site.set_pending_plan_started_at; site.set_pending_plan_cycle_dates }
          end

          its(:pending_plan_cycle_started_at)     { should eq Time.now.utc.midnight }
          its('pending_plan_cycle_ended_at.to_i') { should eq 1.month.from_now.yesterday.end_of_day.to_i }
        end

        context 'will downgrade to paid' do
          let(:site) { create(:site, plan_id: @custom_plan.token) }
          before do
            site.next_cycle_plan_id = @paid_plan.id
            Timecop.travel(2.days.from_now) { site.set_pending_plan_cycle_dates }
          end

          its(:pending_plan_cycle_started_at) { should be_nil }
          its(:pending_plan_cycle_ended_at)   { should be_nil }
        end

        context 'will downgrade to free' do
          before do
            site.next_cycle_plan_id = @free_plan.id
            Timecop.travel(2.days.from_now) { site.set_pending_plan_cycle_dates }
          end

          its(:pending_plan_cycle_started_at) { should be_nil }
          its(:pending_plan_cycle_ended_at)   { should be_nil }
        end

        context 'renew' do
          context 'normal state' do
            before do
              site # eager loading!
              Timecop.travel(1.month.from_now) { site.set_pending_plan_cycle_dates }
            end

            its(:pending_plan_cycle_started_at)     { should eq 1.month.from_now.midnight }
            its('pending_plan_cycle_ended_at.to_i') { should eq 2.months.from_now.yesterday.end_of_day.to_i }
          end

          context 'with downgrade to free' do
            before do
              site.pending_plan_id = @free_plan.id
              Timecop.travel(1.month.from_now) { site.set_pending_plan_started_at; site.set_pending_plan_cycle_dates }
            end

            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
          end

          context 'with downgrade to paid' do
            let(:site) { create(:site, plan_id: @custom_plan.token) }
            before do
              site.pending_plan_id = @paid_plan.id
              Timecop.travel(1.month.from_now) { site.set_pending_plan_started_at; site.set_pending_plan_cycle_dates }
            end

            its(:pending_plan_cycle_started_at) { should eq 1.month.from_now.midnight }
            its(:pending_plan_cycle_ended_at)   { should eq (1.month + 1.month).from_now.yesterday.end_of_day }
          end
        end
      end
    end # #set_pending_plan_cycle_dates

    describe '#apply_pending_attributes' do
      before do
        @site = create(:site, plan_id: @free_plan.id)
        @site.pending_plan_id                           = @paid_plan.id
        @site.pending_plan_started_at                   = Time.utc(2012,12,21)
        @site.pending_plan_cycle_started_at             = Time.utc(2012,12,21)
        @site.pending_plan_cycle_ended_at               = Time.utc(2013,12,20)
        @site.first_plan_upgrade_required_alert_sent_at = Time.utc(2012,11,10)

        @site.apply_pending_attributes
      end
      subject { @site }

      its(:first_plan_upgrade_required_alert_sent_at) { should be_nil }

      its(:plan_id)               { should eq @paid_plan.id }
      its(:plan_started_at)       { should eq Time.utc(2012,12,21) }
      its(:plan_cycle_started_at) { should eq Time.utc(2012,12,21) }
      its(:plan_cycle_ended_at)   { should eq Time.utc(2013,12,20).end_of_day }

      its(:pending_plan_id)               { should be_nil }
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
            Timecop.travel(1.day.from_now) do
              @site.send(:advance_for_next_cycle_end, @plan).should eq 1.month - 1.day
            end
          end
        end

        context "when now is 2 months after start time" do
          it "should return 3 month in advance - 1 day" do
            Timecop.travel(1.day.from_now + 1.day) do
              @site.send(:advance_for_next_cycle_end, @plan, 2.month.ago).should eq 3.months - 1.day
            end
          end
        end

        1.upto(13) do |i|
          context "when now is #{i} months after site.plan_started_at" do
            it "should return #{i+1} months in advance - 1 day" do
              Timecop.travel(Time.now.utc.midnight + i.months + 1.day) do
                @site.send(:advance_for_next_cycle_end, @plan).should eq (i + 1).months - 1.day
              end
            end
          end
        end
      end

      context "with a yearly plan" do
        before { @plan = create(:plan, cycle: "year") }

        context "when now is less than 1 year after site.plan_started_at" do
          it "should return 12 months in advance - 1 day" do
            Timecop.travel(Time.now.utc.midnight + 1.day) do
              @site.send(:advance_for_next_cycle_end, @plan).should eq 12.months - 1.day
            end
          end
        end

        context "when now is more than 1 year after site.plan_started_at" do
          1.upto(3) do |i|
            it "should return #{i*12 + 12} months in advance - 1 day" do
              Timecop.travel(Time.now.utc.midnight + i.years + 1.day) do
                @site.send(:advance_for_next_cycle_end, @plan).should eq (i*12 + 12).months - 1.day
              end
            end
          end
        end
      end
    end # #advance_for_next_cycle_end

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
    end # #months_since

    describe "#days_since" do
      before { @site = create(:site) }

      context "with first_paid_plan_started_at 2011,1,1" do
        before { @site.first_paid_plan_started_at = Time.utc(2011,1,1) }

        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.days_since(nil).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.days_since(@site.first_paid_plan_started_at).should eq 0 } }
        specify { Timecop.travel(Time.utc(2011,1,31)) { @site.days_since(@site.first_paid_plan_started_at).should eq 30 } }
        specify { Timecop.travel(Time.utc(2011,2,1))  { @site.days_since(@site.first_paid_plan_started_at).should eq 31 } }
        specify { Timecop.travel(Time.utc(2011,2,28)) { @site.days_since(@site.first_paid_plan_started_at).should eq 58 } }
        specify { Timecop.travel(Time.utc(2011,3,1))  { @site.days_since(@site.first_paid_plan_started_at).should eq 59 } }
        specify { Timecop.travel(Time.utc(2012,3,1))  { @site.days_since(@site.first_paid_plan_started_at).should eq 425 } }
        specify { Timecop.travel(Time.utc(2012,1,1))  { @site.days_since(@site.first_paid_plan_started_at).should eq 365 } }
        specify { Timecop.travel(Time.utc(2013,1,1))  { @site.days_since(@site.first_paid_plan_started_at).should eq 731 } }
      end
    end # #days_since

  end # Instance Methods

end
