require 'spec_helper'

describe Site::Invoice do

  describe "Class Methods" do

    describe ".delay_renew_active_sites!" do
      it "should delay renew_active_sites! if not already delayed" do
        expect { Site.delay_renew_active_sites! }.should change(Delayed::Job.where(:handler.matches => '%Site%renew_active_sites!%'), :count).by(1)
      end

      it "should not delay renew_active_sites! if already delayed" do
        Site.delay_renew_active_sites!
        expect { Site.delay_renew_active_sites! }.should change(Delayed::Job.where(:handler.matches => '%Site%renew_active_sites!%'), :count).by(0)
      end
    end # .delay_renew_active_sites!

    describe ".renew_active_sites!" do
      before(:all) do
        Site.delete_all
        Timecop.travel(2.months.ago) do
          @site_to_be_renewed = Factory(:site_with_invoice)
          @site_to_be_renewed_with_downgrade_to_dev_plan = Factory(:site_with_invoice)
          @site_to_be_renewed_with_downgrade_to_dev_plan.update_attribute(:next_cycle_plan_id, @dev_plan.id)
          @site_to_be_renewed_with_downgrade_to_paid_plan = Factory(:site_with_invoice)
          @site_to_be_renewed_with_downgrade_to_paid_plan.update_attribute(:next_cycle_plan_id, @custom_plan.id)
        end
        @site_not_to_be_renewed = Factory(:site_with_invoice, plan_started_at: 3.months.ago, plan_cycle_ended_at: 2.months.from_now)

        @site_to_be_renewed.invoices.size.should == 1
        @site_to_be_renewed_with_downgrade_to_dev_plan.invoices.size.should == 1
        @site_to_be_renewed_with_downgrade_to_paid_plan.invoices.size.should == 1
        @site_not_to_be_renewed.invoices.size.should == 1
      end

      before(:each) do
        @site_to_be_renewed.reload
        @site_to_be_renewed_with_downgrade_to_dev_plan.reload
        @site_to_be_renewed_with_downgrade_to_paid_plan.reload
        @site_not_to_be_renewed.reload

        @site_to_be_renewed.pending_plan_cycle_started_at.should be_nil
        @site_to_be_renewed.pending_plan_cycle_ended_at.should be_nil

        Transaction.should_not_receive(:charge_by_invoice_ids)

        Delayed::Job.delete_all
        Site.renew_active_sites!
      end

      it "should create invoices for renewable sites" do
        @site_to_be_renewed.reload.invoices.count.should == 2
        @site_to_be_renewed_with_downgrade_to_dev_plan.reload.invoices.count.should == 1
        @site_to_be_renewed_with_downgrade_to_paid_plan.reload.invoices.count.should == 2
        @site_not_to_be_renewed.reload.invoices.count.should == 1
      end

      it "should update plan cycle dates" do
        @site_to_be_renewed.reload.pending_plan_cycle_started_at.should be_present
        @site_to_be_renewed.reload.pending_plan_cycle_ended_at.should be_present
      end

      it "should update plan of downgraded sites" do
        @site_to_be_renewed_with_downgrade_to_dev_plan.reload.next_cycle_plan_id.should be_nil
        @site_to_be_renewed_with_downgrade_to_dev_plan.reload.plan_id.should == @dev_plan.id
        @site_to_be_renewed_with_downgrade_to_paid_plan.reload.next_cycle_plan_id.should be_nil
        @site_to_be_renewed_with_downgrade_to_paid_plan.reload.pending_plan_id.should == @custom_plan.id
      end

      it "should set the renew flag to true" do
        @site_to_be_renewed.reload.invoices.by_date('asc').last.should be_renew
        @site_to_be_renewed_with_downgrade_to_dev_plan.reload.invoices.by_date('asc').last.should_not be_renew
        @site_to_be_renewed_with_downgrade_to_paid_plan.reload.invoices.by_date('asc').last.should be_renew
        @site_not_to_be_renewed.reload.invoices.by_date('asc').last.should_not be_renew
      end

      it "should delay renew_active_sites!" do
        Delayed::Job.where(:handler.matches => '%Site%renew_active_sites!%').count.should == 1
      end
    end # .renew_active_sites!

  end # Class Methods

  describe "Instance Methods" do

    describe "invoices_failed?" do
      subject do
        site = Factory(:site)
        Factory(:invoice, site: site , state: 'failed')
        site
      end

      its(:invoices_failed?) { should be_true }
    end

    describe "invoices_waiting?" do
      subject do
        site = Factory(:site)
        Factory(:invoice, site: site , state: 'waiting')
        site
      end

      its(:invoices_waiting?) { should be_true }
    end

    describe "#invoices_open?" do
      before(:all) do
        @site = Factory(:site)
      end
      before(:each) { Invoice.delete_all }
      subject { @site }

      context "with no options" do
        it "should be true if invoice have the renew flag == false" do
          invoice = Factory(:invoice, state: 'open', site: @site, renew: false)
          invoice.renew.should be_false
          subject.invoices_open?.should be_true
        end

        it "should be true if invoice have the renew flag == true" do
          invoice = Factory(:invoice, state: 'open', site: @site, renew: true)
          invoice.renew.should be_true
          subject.invoices_open?.should be_true
        end
      end

      context "with options[:renew] == true" do
        it "should be false if no invoice with the renew flag == true" do
          invoice = Factory(:invoice, state: 'open', site: @site, renew: false)
          invoice.renew.should be_false
          subject.invoices_open?(renew: true).should be_false
        end

        it "should be true if invoice with the renew flag == true" do
          invoice = Factory(:invoice, state: 'open', site: @site, renew: true)
          invoice.renew.should be_true
          subject.invoices_open?(renew: true).should be_true
        end
      end

      context "with options[:renew] == false" do
        it "should be false if no invoice with the renew flag == true" do
          invoice = Factory(:invoice, state: 'open', site: @site, renew: false)
          invoice.renew.should be_false
          subject.invoices_open?(renew: false).should be_true
        end

        it "should be true if invoice with the renew flag == true" do
          invoice = Factory(:invoice, state: 'open', site: @site, renew: true)
          invoice.renew.should be_true
          subject.invoices_open?(renew: false).should be_false
        end
      end
    end

    describe "#in_beta_plan?" do
      subject { Factory(:site, plan_id: @beta_plan.id) }

      it { should be_in_beta_plan }
    end # #in_beta_plan?

    describe "#in_dev_plan?" do
      subject { Factory(:site, plan_id: @dev_plan.id) }

      it { should be_in_dev_plan }
    end # #in_dev_plan?

    describe "#in_sponsored_plan?" do
      subject { site = Factory(:site); site.sponsor!; site.reload }

      it { should be_in_sponsored_plan }
    end # #in_sponsored_plan?

    describe "#in_paid_plan?" do
      context "standard plan" do
        subject { Factory(:site, plan_id: @paid_plan.id) }
        it { should be_in_paid_plan }
      end

      context "custom plan" do
        subject { Factory(:site, plan_id: @custom_plan.token) }
        it { should be_in_paid_plan }
      end
    end # #in_paid_plan?

    describe "#instant_charging?" do
      subject { Factory(:site) }

      specify do
        subject.instance_variable_set("@instant_charging", false)
        should_not be_instant_charging
      end

      specify do
        subject.instance_variable_set("@instant_charging", true)
        should be_instant_charging
      end
    end # #instant_charging?

    describe "#in_or_will_be_in_paid_plan?" do
      context "site in paid plan" do
        subject { Factory(:site, plan_id: @paid_plan.id) }

        it { should be_in_or_will_be_in_paid_plan }
      end

      context "site is dev and updated to paid" do
        before(:each) do
          @site = Factory(:site, plan_id: @dev_plan.id)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        it { should be_in_or_will_be_in_paid_plan }
      end

      context "site is paid is now paid" do
        before(:each) do
          @site = Factory(:site, plan_id: @paid_plan.id)
          @site.plan_id = @dev_plan.id
        end
        subject { @site }

        it { should be_in_or_will_be_in_paid_plan }
      end
    end # #in_or_will_be_in_paid_plan?

    describe "#will_be_in_dev_plan?" do

      context "site in dev plan" do
        subject { Factory(:site, plan_id: @dev_plan.id) }

        it { should_not be_will_be_in_dev_plan }
      end

      context "site in paid plan" do
        subject { Factory(:site, plan_id: @paid_plan.id) }

        it { should_not be_will_be_in_dev_plan }
      end

      context "site in build dev plan" do
        subject { Factory.build(:new_site, plan_id: @dev_plan.id) }

        it { should be_will_be_in_dev_plan }
      end

      context "site is paid and updated to dev" do
        before(:each) do
          @site = Factory(:site, plan_id: @paid_plan.id)
          @site.plan_id = @dev_plan.id
        end
        subject { @site }

        it { should be_will_be_in_dev_plan }
      end
    end # #will_be_in_dev_plan?

    describe "#will_be_in_paid_plan?" do
      context "site in paid plan" do
        subject { Factory(:site, plan_id: @paid_plan.id) }

        it { should_not be_will_be_in_paid_plan }
      end

      context "site is dev and updated to paid" do
        before(:each) do
          @site = Factory(:site, plan_id: @dev_plan.id)
          @site.plan_id = @paid_plan.id
        end
        subject { @site }

        it { should be_will_be_in_paid_plan }
      end

      context "site is paid and updated to paid" do
        before(:each) do
          @site = Factory(:site, plan_id: @paid_plan.id)
          @new_plan = Factory(:plan, price: @paid_plan.price + 1000)
          @site.plan_id = @new_plan.id
        end
        subject { @site }

        its(:pending_plan_id) { should == @new_plan.id }
        it { should be_will_be_in_paid_plan }
      end

      context "site is paid and updated to dev" do
        before(:each) do
          @site = Factory(:site, plan_id: @paid_plan.id)
          @site.plan_id = @dev_plan.id
        end
        subject { @site }

        it { should_not be_will_be_in_paid_plan }
      end
    end # #will_be_in_paid_plan?

    describe "#last_paid_invoice" do
      context "with the last paid invoice not refunded" do
        subject { Factory(:site_with_invoice, plan_id: @paid_plan.id) }

        it "should return the last paid invoice" do
          subject.last_paid_invoice.should == subject.invoices.paid.last
        end
      end

      context "with the last paid invoice refunded" do
        before(:all) do
          @site = Factory(:site_with_invoice, plan_id: @paid_plan.id)
          @site.refund
        end
        subject { @site.reload }

        it "returns nil" do
          subject.refunded_at.should be_present
          subject.last_paid_invoice.should be_nil
        end
      end
    end # #last_paid_invoice

    describe "#last_paid_plan_price" do
      context "site with no invoice" do
        subject { Factory(:site, plan_id: @dev_plan.id) }

        its(:last_paid_plan_price) { should == 0 }
      end

      context "site with at least one paid invoice" do
        before(:all) do
          @plan1 = Factory(:plan, price: 10_000)
          @plan2 = Factory(:plan, price: 5_000)
          @site  = Factory(:site_with_invoice, plan_id: @plan1.id)
          @site.plan_id = @plan2.id
        end
        subject { @site }

        it "should return the price of the last InvoiceItem::Plan with an price > 0" do
          subject.last_paid_plan_price.should == @plan1.price(subject)
        end
      end
    end # #last_paid_plan_price

    describe "#refund" do
      before(:all) do
        @site = Factory(:new_site, first_paid_plan_started_at: nil)
      end

      it "touches refunded_at" do
        @site.refunded_at.should be_nil
        @site.refund
        @site.reload.refunded_at.should be_present
      end

      it "delays Transactions.refund_by_site_id" do
        expect { @site.refund }.to change(Delayed::Job.where(:handler.matches => "%refund_by_site_id%"), :count).by(1)
      end
    end # #refund

    describe "#pend_plan_changes" do
      before(:all) do
        @paid_plan         = Factory(:plan, cycle: "month", price: 1000)
        @paid_plan2        = Factory(:plan, cycle: "month", price: 5000)
        @paid_plan_yearly  = Factory(:plan, cycle: "year",  price: 10000)
        @paid_plan_yearly2 = Factory(:plan, cycle: "year",  price: 50000)
      end

      describe "new site" do
        context "with dev plan" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) do
              @site = Factory.build(:new_site, plan_id: @dev_plan.id)
              @site.pend_plan_changes
            end
          end
          subject { @site }

          its(:pending_plan_started_at)       { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_started_at) { should be_nil }
          its(:pending_plan_cycle_ended_at)   { should be_nil }
          its(:plan)                          { should be_nil }
          its(:pending_plan)                  { should == @dev_plan }
          its(:next_cycle_plan)               { should be_nil }
          it { should be_instant_charging }
        end

        context "with monthly paid plan" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site_pending, plan_id: @paid_plan.id) }
          end
          subject { @site }

          its(:pending_plan_started_at)       { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_ended_at)   { should == Time.utc(2011,2,27).to_datetime.end_of_day }
          its(:plan)                          { should be_nil }
          its(:pending_plan)                  { should == @paid_plan }
          its(:next_cycle_plan)               { should be_nil }
          it { should be_instant_charging }
        end

        context "with yearly paid plan" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site_pending, plan_id: @paid_plan_yearly.id) }
          end
          subject { @site }

          its(:pending_plan_started_at)       { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_ended_at)   { should == Time.utc(2012,1,29).to_datetime.end_of_day }
          its(:plan)                          { should be_nil }
          its(:pending_plan)                  { should == @paid_plan_yearly }
          its(:next_cycle_plan)               { should be_nil }
          it { should be_instant_charging }
        end
      end

      describe "upgrade site" do
        context "from dev plan to monthly paid plan" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan_id: @dev_plan.id) }
            @site.apply_pending_plan_changes
            VCR.use_cassette('ogone/visa_payment_generic') do
              @site.reload.plan_id = @paid_plan.id # upgrade
              Timecop.travel(Time.utc(2011,2,25)) { @site.pend_plan_changes }
            end
          end
          subject { @site }

          its(:pending_plan_started_at)       { should == Time.utc(2011,2,25).midnight }
          its(:pending_plan_cycle_started_at) { should == Time.utc(2011,2,25).midnight }
          its(:pending_plan_cycle_ended_at)   { should == Time.utc(2011,3,24).to_datetime.end_of_day }
          its(:plan)                          { should == @dev_plan }
          its(:pending_plan)                  { should == @paid_plan }
          its(:next_cycle_plan)               { should be_nil }
          it { should be_instant_charging }
        end

        context "from dev plan to yearly paid plan" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan_id: @dev_plan.id) }
            @site.apply_pending_plan_changes
            VCR.use_cassette('ogone/visa_payment_generic') do
              @site.reload.plan_id = @paid_plan_yearly.id # upgrade
              Timecop.travel(Time.utc(2011,2,25)) { @site.pend_plan_changes }
            end
          end
          subject { @site }

          its(:pending_plan_started_at)       { should == Time.utc(2011,2,25).midnight }
          its(:pending_plan_cycle_started_at) { should == Time.utc(2011,2,25).midnight }
          its(:pending_plan_cycle_ended_at)   { should == Time.utc(2012,2,24).to_datetime.end_of_day }
          its(:plan)                          { should == @dev_plan }
          its(:pending_plan)                  { should == @paid_plan_yearly }
          its(:next_cycle_plan)               { should be_nil }
          it { should be_instant_charging }
        end

        context "from monthly paid plan to monthly paid plan" do
          before(:all) do
            VCR.use_cassette('ogone/visa_payment_generic') do
              @site = Factory.build(:new_site, plan_id: @paid_plan.id)
              Timecop.travel(Time.utc(2011,1,30)) { @site.pend_plan_changes }
              @site.apply_pending_plan_changes
              @site.reload.plan_id = @paid_plan2.id # upgrade
              Timecop.travel(Time.utc(2011,2,25)) { @site.pend_plan_changes }
            end
          end
          subject { @site }

          its(:pending_plan_started_at)       { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_ended_at)   { should == Time.utc(2011,2,27).to_datetime.end_of_day }
          its(:plan)                          { should == @paid_plan }
          its(:pending_plan)                  { should == @paid_plan2 }
          its(:next_cycle_plan)               { should be_nil }
          it { should be_instant_charging }
        end

        context "from monthly paid plan to yearly paid plan" do
          before(:all) do
            VCR.use_cassette('ogone/visa_payment_generic') do
              @site = Factory.build(:new_site, plan_id: @paid_plan.id)
              Timecop.travel(Time.utc(2011,1,30)) { @site.pend_plan_changes }
              @site.apply_pending_plan_changes
              @site.reload.plan_id = @paid_plan_yearly.id # upgrade
              Timecop.travel(Time.utc(2011,2,25)) { @site.pend_plan_changes }
            end
          end
          subject { @site }

          its(:pending_plan_started_at)       { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_ended_at)   { should == Time.utc(2012,1,29).to_datetime.end_of_day }
          its(:plan)                          { should == @paid_plan }
          its(:pending_plan)                  { should == @paid_plan_yearly }
          its(:next_cycle_plan)               { should be_nil }
          it { should be_instant_charging }
        end

        context "from yearly paid plan to yearly paid plan" do
          before(:all) do
            VCR.use_cassette('ogone/visa_payment_generic') do
              @site = Factory.build(:new_site, plan_id: @paid_plan_yearly.id)
              Timecop.travel(Time.utc(2011,1,30)) { @site.pend_plan_changes }
              @site.apply_pending_plan_changes
              @site.reload.plan_id = @paid_plan_yearly2.id # upgrade
              Timecop.travel(Time.utc(2011,2,25)) { @site.pend_plan_changes }
            end
          end
          subject { @site }

          its(:pending_plan_started_at)       { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
          its(:pending_plan_cycle_ended_at)   { should == Time.utc(2012,1,29).to_datetime.end_of_day }
          its(:plan)                          { should == @paid_plan_yearly }
          its(:pending_plan)                  { should == @paid_plan_yearly2 }
          its(:next_cycle_plan)               { should be_nil }
          it { should be_instant_charging }
        end
      end

      describe "renew/downgrade site" do
        context "without downgrade" do
          before(:all) do
            VCR.use_cassette('ogone/visa_payment_generic') do
              @site = Factory.build(:new_site, plan_id: @paid_plan.id)
              Timecop.travel(Time.utc(2011,1,30)) { @site.pend_plan_changes }
              @site.apply_pending_plan_changes
              Timecop.travel(Time.utc(2011,3,3)) { @site.pend_plan_changes }
            end
          end
          subject { @site }

          its(:pending_plan_started_at)       { should be_nil }
          its(:pending_plan_cycle_started_at) { should == Time.utc(2011,2,28).midnight }
          its(:pending_plan_cycle_ended_at)   { should == Time.utc(2011,3,29).to_datetime.end_of_day }
          its(:plan)                          { should == @paid_plan }
          its(:pending_plan)                  { should == @paid_plan }
          its(:next_cycle_plan)               { should be_nil }
          it { should_not be_instant_charging }
        end

        context "with downgrade" do
          context "from monthly paid plan to dev plan" do
            before(:all) do
              VCR.use_cassette('ogone/visa_payment_generic') do
                @site = Factory.build(:new_site, plan_id: @paid_plan.id)
                Timecop.travel(Time.utc(2011,1,30)) { @site.pend_plan_changes }
                @site.apply_pending_plan_changes
                @site.reload.plan_id = @dev_plan.id # downgrade
                Timecop.travel(Time.utc(2011,3,3)) { @site.pend_plan_changes }
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should == Time.utc(2011,2,28).midnight }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should == @paid_plan }
            its(:pending_plan)                  { should == @dev_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_instant_charging }
          end

          context "from yearly paid plan to dev plan" do
            before(:all) do
              VCR.use_cassette('ogone/visa_payment_generic') do
                @site = Factory.build(:new_site, plan_id: @paid_plan_yearly.id)
                Timecop.travel(Time.utc(2011,1,30)) { @site.pend_plan_changes }
                @site.apply_pending_plan_changes
                @site.reload.plan_id = @dev_plan.id # downgrade
                Timecop.travel(Time.utc(2012,3,3)) { @site.pend_plan_changes }
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should == Time.utc(2012,1,30).midnight }
            its(:pending_plan_cycle_started_at) { should be_nil }
            its(:pending_plan_cycle_ended_at)   { should be_nil }
            its(:plan)                          { should == @paid_plan_yearly }
            its(:pending_plan)                  { should == @dev_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_instant_charging }
          end

          context "from monthly paid plan to monthly paid plan" do
            before(:all) do
              VCR.use_cassette('ogone/visa_payment_generic') do
                @site = Factory.build(:new_site, plan_id: @paid_plan2.id)
                Timecop.travel(Time.utc(2011,1,30)) { @site.pend_plan_changes }
                @site.apply_pending_plan_changes
                @site.reload.plan_id = @paid_plan.id # downgrade
                Timecop.travel(Time.utc(2011,3,3)) { @site.pend_plan_changes }
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should == Time.utc(2011,2,28).midnight }
            its(:pending_plan_cycle_started_at) { should == Time.utc(2011,2,28).midnight }
            its(:pending_plan_cycle_ended_at)   { should == Time.utc(2011,3,27).to_datetime.end_of_day }
            its(:plan)                          { should == @paid_plan2 }
            its(:pending_plan)                  { should == @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_instant_charging }
          end

          context "from yearly paid plan to yearly paid plan" do
            before(:all) do
              VCR.use_cassette('ogone/visa_payment_generic') do
                @site = Factory.build(:new_site, plan_id: @paid_plan_yearly2.id)
                Timecop.travel(Time.utc(2011,1,30)) { @site.pend_plan_changes }
                @site.apply_pending_plan_changes
                @site.reload.plan_id = @paid_plan_yearly.id # downgrade
                Timecop.travel(Time.utc(2012,2,15)) { @site.pend_plan_changes }
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should == Time.utc(2012,1,30).midnight }
            its(:pending_plan_cycle_started_at) { should == Time.utc(2012,1,30).midnight }
            its(:pending_plan_cycle_ended_at)   { should == Time.utc(2013,1,29).to_datetime.end_of_day }
            its(:plan)                          { should == @paid_plan_yearly2 }
            its(:pending_plan)                  { should == @paid_plan_yearly }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_instant_charging }
          end

          context "from yearly paid plan to monthly paid plan" do
            before(:all) do
              VCR.use_cassette('ogone/visa_payment_generic') do
                @site = Factory.build(:new_site, plan_id: @paid_plan_yearly.id)
                Timecop.travel(Time.utc(2011,1,30)) { @site.pend_plan_changes }
                @site.apply_pending_plan_changes
                @site.reload.plan_id = @paid_plan.id # downgrade
                Timecop.travel(Time.utc(2012,2,25)) { @site.pend_plan_changes }
              end
            end
            subject { @site }

            its(:pending_plan_started_at)       { should == Time.utc(2012,1,30).midnight }
            its(:pending_plan_cycle_started_at) { should == Time.utc(2012,1,30).midnight }
            its(:pending_plan_cycle_ended_at)   { should == Time.utc(2012,2,28).to_datetime.end_of_day }
            its(:plan)                          { should == @paid_plan_yearly }
            its(:pending_plan)                  { should == @paid_plan }
            its(:next_cycle_plan)               { should be_nil }
            it { should_not be_instant_charging }
          end
        end
      end
    end # #pend_plan_changes

    describe "#apply_pending_plan_changes" do
      before(:all) do
        @site = Factory(:site, plan_id: @dev_plan.id)
        @site = Site.find(@site) # hard reset to plan association cache
        @site.pending_plan_id                           = @paid_plan.id
        @site.pending_plan_started_at                   = Time.utc(2012,12,21)
        @site.pending_plan_cycle_started_at             = Time.utc(2012,12,21)
        @site.pending_plan_cycle_ended_at               = Time.utc(2013,12,20)
        @site.first_plan_upgrade_required_alert_sent_at = Time.utc(2012,11,10)

        @site.apply_pending_plan_changes
      end
      subject { @site }

      it { should be_persisted }

      its(:first_plan_upgrade_required_alert_sent_at) { should be_nil }

      its(:plan_id)               { should == @paid_plan.id }
      its(:plan)                  { should == @paid_plan }
      its(:plan_started_at)       { should == Time.utc(2012,12,21) }
      its(:plan_cycle_started_at) { should == Time.utc(2012,12,21) }
      its(:plan_cycle_ended_at)   { should == Time.utc(2013,12,20) }

      its(:pending_plan_id)               { should be_nil }
      its(:pending_plan)                  { should be_nil }
      its(:pending_plan_started_at)       { should be_nil }
      its(:pending_plan_cycle_started_at) { should be_nil }
      its(:pending_plan_cycle_ended_at)   { should be_nil }

    end # #apply_pending_plan_changes

    describe "#months_since" do
      before(:all) { @site = Factory.build(:new_site) }

      context "with plan_started_at 2011,1,1" do
        before(:all) { @start_time = Time.utc(2011,1,1) }

        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.months_since(nil).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.months_since(@start_time).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,1,31)) { @site.months_since(@start_time).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,2,1))  { @site.months_since(@start_time).should == 1 } }
        specify { Timecop.travel(Time.utc(2011,2,15)) { @site.months_since(@start_time).should == 1 } }
        specify { Timecop.travel(Time.utc(2011,2,28)) { @site.months_since(@start_time).should == 1 } }
        specify { Timecop.travel(Time.utc(2012,1,1))  { @site.months_since(@start_time).should == 12 } }
        specify { Timecop.travel(Time.utc(2013,1,15)) { @site.months_since(@start_time).should == 24 } }
      end

      context "with plan_started_at 2011,6,15" do
        before(:all) { @start_time = Time.utc(2011,6,15) }

        specify { Timecop.travel(Time.utc(2011,6,20)) { @site.months_since(nil).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,6,20)) { @site.months_since(@start_time).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,6,31)) { @site.months_since(@start_time).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,7,10)) { @site.months_since(@start_time).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,7,15)) { @site.months_since(@start_time).should == 1 } }
        specify { Timecop.travel(Time.utc(2011,7,25)) { @site.months_since(@start_time).should == 1 } }
        specify { Timecop.travel(Time.utc(2012,6,10)) { @site.months_since(@start_time).should == 11 } }
        specify { Timecop.travel(Time.utc(2012,6,15)) { @site.months_since(@start_time).should == 12 } }
        specify { Timecop.travel(Time.utc(2012,6,20)) { @site.months_since(@start_time).should == 12 } }
        specify { Timecop.travel(Time.utc(2012,6,25)) { @site.months_since(@start_time).should == 12 } }
      end
    end # #months_since

    describe "#advance_for_next_cycle_end" do
      before(:all) do
        @site = Factory.build(:new_site, plan_id: @paid_plan.id)
        @site.pend_plan_changes
        @site.apply_pending_plan_changes
      end

      context "with a monthly plan" do
        before(:all) { @plan = Factory(:plan, cycle: "month") }

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
        before(:all) { @plan = Factory(:plan, cycle: "year") }

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

    # recurrent
      # site.pend_plan_changes
      # site.save
      # apply_pending_plan_changes => will create invoice without charging it

    # upfront
      # plan_id = ... (set pending_plan_id, pending dates and pend_plan_changes)
      # save (create the invoice and charge it)
      # apply_pending_plan_changes when transaction is ok
    describe "#create_and_charge_invoice" do
      before(:all) do
        @paid_plan         = Factory(:plan, cycle: "month", price: 1000)
        @paid_plan2        = Factory(:plan, cycle: "month", price: 5000)
        @paid_plan_yearly  = Factory(:plan, cycle: "year",  price: 10000)
        @paid_plan_yearly2 = Factory(:plan, cycle: "year",  price: 50000)
      end

      context "site in dev plan" do
        context "on creation" do
          before(:each) { @site = Factory.build(:new_site, plan_id: @dev_plan.id) }
          subject { @site }

          it "should not create and not try to charge the invoice" do
            expect { subject.save! }.to_not change(subject.invoices, :count)
            subject.reload.plan.should == @dev_plan
          end
        end

        context "on a saved record" do
          before(:all) { Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site_with_invoice, plan_id: @dev_plan.id) } }

          describe "when save with no changes" do
            subject { @site }

            it "should not create and not try to charge the invoice" do
              expect { Timecop.travel(Time.utc(2011,3,3)) { subject.save! } }.to_not change(subject.invoices, :count)
              subject.reload.plan.should == @dev_plan
            end
          end

          describe "when upgrade to monthly paid plan" do
            use_vcr_cassette "ogone/visa_payment_generic"
            subject { @site.reload }

            it "should create and try to charge the invoice" do
              subject.plan_id = @paid_plan.id
              subject.user_attributes = { current_password: "123456" }
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save! }.to change(subject.invoices, :count).by(1) }
              subject.reload.plan.should == @paid_plan
              subject.last_invoice.should be_paid
            end
          end

          describe "when upgrade to yearly paid plan" do
            use_vcr_cassette "ogone/visa_payment_generic"
            before(:each) { @site.reload.plan_id = @paid_plan_yearly.id }
            subject { @site }

            it "should create and try to charge the invoice" do
              subject.user_attributes = { current_password: "123456" }
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save! }.to change(subject.invoices, :count).by(1) }
              subject.reload.plan.should == @paid_plan_yearly
              subject.last_invoice.should be_paid
            end
          end

          describe "when suspend" do
            subject { @site }

            it "should not create and not try to charge the invoice" do
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.suspend! }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @dev_plan
              subject.should be_suspended
            end
          end

          describe "when archive" do
            subject { @site }

            it "should not create and not try to charge the invoice" do
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.archive! }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @dev_plan
              subject.should be_archived
            end
          end
        end
      end # context "site in dev plan"

      context "site in beta plan" do
        context "on creation" do
          before(:each) { Timecop.travel(Time.utc(2011,1,30)) { @site = Factory.build(:new_site, plan_id: @beta_plan.id) } }
          subject { @site }

          it "should not create and not try to charge the invoice" do
            expect { subject.save }.to_not change(subject.invoices, :count)
            subject.reload.plan.should == @beta_plan
          end
        end

        context "on a saved record" do
          before(:all) { Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site_with_invoice, plan_id: @beta_plan.id) } }

          describe "when save with no changes" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              expect { Timecop.travel(Time.utc(2011,3,3)) { subject.save! } }.to_not change(subject.invoices, :count)
              subject.reload.plan.should == @beta_plan
            end
          end

          describe "when upgrade to monthly paid plan" do
            use_vcr_cassette "ogone/visa_payment_generic"
            before(:each) { @site.reload.plan_id = @paid_plan.id }
            subject { @site }

            it "should create and try to charge the invoice" do
              subject.user_attributes = { current_password: "123456" }
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save! }.to change(subject.invoices, :count).by(1) }
              subject.reload.plan.should == @paid_plan
              subject.last_invoice.should be_paid
            end
          end

          describe "when upgrade to yearly paid plan" do
            use_vcr_cassette "ogone/visa_payment_generic"
            before(:each) { @site.reload.plan_id = @paid_plan_yearly.id }
            subject { @site }

            it "should create and try to charge the invoice" do
              subject.user_attributes = { current_password: "123456" }
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save! }.to change(subject.invoices, :count).by(1) }
              subject.reload.plan.should == @paid_plan_yearly
              subject.last_invoice.should be_paid
            end
          end

          describe "when suspend" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.suspend! }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @beta_plan
              subject.should be_suspended
            end
          end

          describe "when archive" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.archive! }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @beta_plan
              subject.should be_archived
            end
          end
        end
      end # context "site in beta plan"

      context "site in monthly paid plan" do
        context "on creation" do
          use_vcr_cassette "ogone/visa_payment_generic"
          before(:each) { Timecop.travel(Time.utc(2011,1,30)) { @site = Factory.build(:new_site, plan_id: @paid_plan.id) } }
          subject { @site }

          it "should create and try to charge the invoice" do
            expect { subject.save }.to change(subject.invoices, :count).by(1)
            subject.reload.plan.should == @paid_plan
            subject.last_invoice.should be_paid
          end
        end

        context "on a saved record" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site_with_invoice, plan_id: @paid_plan.id) }
          end

          describe "when save with no changes during the first cycle" do
            subject { @site }

            it "should not create and not try to charge the invoice" do
              Timecop.travel(Time.utc(2011,2,3)) do
                subject.pend_plan_changes
                expect { subject.save! }.to_not change(subject.invoices, :count)
              end
              subject.reload.plan.should == @paid_plan
            end
          end

          describe "when save with no changes during the second cycle" do
            use_vcr_cassette "ogone/visa_payment_generic"
            subject { @site }

            it "should create and try to charge the invoice" do
              Timecop.travel(Time.utc(2011,3,3)) do
                subject.pend_plan_changes
                expect { subject.save! }.to change(subject.invoices, :count).by(1)
              end
              subject.reload.plan.should == @paid_plan
            end
          end

          describe "when upgrade to monthly paid plan" do
            use_vcr_cassette "ogone/visa_payment_generic"
            subject { @site.reload }

            it "should create and try to charge the invoice" do
              subject.reload.plan_id  = @paid_plan2.id
              subject.user_attributes = { "current_password" => "123456" }
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save }.to change(subject.invoices, :count).by(1) }
              subject.reload.plan.should == @paid_plan2
              subject.last_invoice.should be_paid
            end
          end

          describe "when upgrade to yearly paid plan" do
            use_vcr_cassette "ogone/visa_payment_generic"
            subject { @site.reload }

            it "should create and try to charge the invoice" do
              subject.reload.plan_id  = @paid_plan_yearly.id
              subject.user_attributes = { "current_password" => "123456" }
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save }.to change(subject.invoices, :count).by(1) }
              subject.reload.plan.should == @paid_plan_yearly
              subject.last_invoice.should be_paid
            end

            it "should save user credit card infos if passed through charging_options" do
              subject.reload.plan_id   = @paid_plan_yearly.id
              subject.user_attributes = { "current_password" => "123456" }
              subject.charging_options = { credit_card: Factory.build(:user_no_cc, valid_cc_attributes_master).credit_card }

              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save }.to change(subject.invoices, :count).by(1) }
              subject.reload.plan.should == @paid_plan_yearly
              subject.last_invoice.should be_paid
            end
          end

          describe "when downgrade" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              subject.reload.plan_id = @dev_plan.id
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save_without_password_validation }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @paid_plan
            end
          end

          describe "when suspend" do
            subject { @site }

            it "should not create and not try to charge the invoice" do
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.suspend! }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @paid_plan
              subject.should be_suspended
            end
          end

          describe "when archive" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              subject.user_attributes = { "current_password" => "123456" }
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.archive! }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @paid_plan
              subject.should be_archived
            end
          end
        end
      end # context "site in monthly paid plan"

      context "site in yearly paid plan" do
        context "on creation" do
          use_vcr_cassette "ogone/visa_payment_generic"
          before(:each) { Timecop.travel(Time.utc(2011,1,30)) { @site = Factory.build(:new_site, plan_id: @paid_plan_yearly.id) } }
          subject { @site }

          it "should create and try to charge the invoice" do
            expect { subject.save }.to change(subject.invoices, :count).by(1)
            subject.reload.plan.should == @paid_plan_yearly
            subject.last_invoice.should be_paid
          end
        end

        context "on a saved record" do
          before(:all) do
            Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site_with_invoice, plan_id: @paid_plan_yearly.id) }
          end

          describe "when save with no changes during the first cycle" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              Timecop.travel(Time.utc(2011,2,3)) do
                subject.pend_plan_changes
                expect { subject.save! }.to_not change(subject.invoices, :count)
              end
              subject.reload.plan.should == @paid_plan_yearly
            end
          end

          describe "when save with no changes during the second cycle" do
            subject { @site.reload }

            it "should create and try to charge the invoice" do
              Timecop.travel(Time.utc(2012,3,3)) do
                subject.pend_plan_changes
                expect { subject.save! }.to change(subject.invoices, :count).by(1)
              end
              subject.reload.plan.should == @paid_plan_yearly
            end
          end

          describe "when upgrade to yearly paid plan" do
            use_vcr_cassette "ogone/visa_payment_generic"
            subject { @site.reload }

            it "should create and try to charge the invoice" do
              subject.reload.plan_id = @paid_plan_yearly2.id
              subject.user_attributes = { "current_password" => "123456" }
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save! }.to change(subject.invoices, :count).by(1) }
              subject.reload.plan.should == @paid_plan_yearly2
              subject.last_invoice.should be_paid
            end
          end

          describe "when downgrade to dev plan" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              subject.reload.plan_id = @dev_plan.id
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save_without_password_validation }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @paid_plan_yearly
            end
          end

          describe "when downgrade to paid plan" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              subject.plan_id = @paid_plan.id
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.save_without_password_validation }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @paid_plan_yearly
            end
          end

          describe "when suspend" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.suspend! }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @paid_plan_yearly
            end
          end

          describe "when archive" do
            subject { @site.reload }

            it "should not create and not try to charge the invoice" do
              subject.user_attributes = { "current_password" => "123456" }
              Timecop.travel(Time.utc(2011,2,10)) { expect { subject.archive! }.to_not change(subject.invoices, :count) }
              subject.reload.plan.should == @paid_plan_yearly
              subject.should be_archived
            end
          end
        end
      end # context "site in yearly paid plan"

    end # #create_and_charge_invoice

    describe "#months_since" do
      before(:all) { @site = Factory(:site) }

      context "with plan_started_at 2011,1,1" do
        before(:all) { @site.plan_started_at = Time.utc(2011,1,1) }

        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.months_since(nil).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,1,1))  { @site.months_since(@site.plan_started_at).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,1,31)) { @site.months_since(@site.plan_started_at).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,2,1))  { @site.months_since(@site.plan_started_at).should == 1 } }
        specify { Timecop.travel(Time.utc(2011,2,15)) { @site.months_since(@site.plan_started_at).should == 1 } }
        specify { Timecop.travel(Time.utc(2011,2,28)) { @site.months_since(@site.plan_started_at).should == 1 } }
        specify { Timecop.travel(Time.utc(2012,1,1))  { @site.months_since(@site.plan_started_at).should == 12 } }
        specify { Timecop.travel(Time.utc(2013,1,15)) { @site.months_since(@site.plan_started_at).should == 24 } }
      end

      context "with plan_started_at 2011,6,15" do
        before(:all) { @site.plan_started_at = Time.utc(2011,6,15) }

        specify { Timecop.travel(Time.utc(2011,6,20)) { @site.months_since(nil).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,6,20)) { @site.months_since(@site.plan_started_at).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,6,31)) { @site.months_since(@site.plan_started_at).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,7,10)) { @site.months_since(@site.plan_started_at).should == 0 } }
        specify { Timecop.travel(Time.utc(2011,7,15)) { @site.months_since(@site.plan_started_at).should == 1 } }
        specify { Timecop.travel(Time.utc(2011,7,25)) { @site.months_since(@site.plan_started_at).should == 1 } }
        specify { Timecop.travel(Time.utc(2012,6,10)) { @site.months_since(@site.plan_started_at).should == 11 } }
        specify { Timecop.travel(Time.utc(2012,6,15)) { @site.months_since(@site.plan_started_at).should == 12 } }
        specify { Timecop.travel(Time.utc(2012,6,20)) { @site.months_since(@site.plan_started_at).should == 12 } }
        specify { Timecop.travel(Time.utc(2012,6,25)) { @site.months_since(@site.plan_started_at).should == 12 } }
      end
    end

    describe "#days_since" do
      before(:all) { @site = Factory(:site) }

      context "with first_paid_plan_started_at 2011,1,1" do
        before(:all) { @site.first_paid_plan_started_at = Time.utc(2011,1,1) }

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

    describe "#advance_for_next_cycle_end" do
      context "with a monthly plan" do
        before(:all) do
          @plan = Factory(:plan, cycle: "month")
          @site = Factory(:site)
          @site.plan_started_at.should == Time.now.utc.midnight
        end
      end
    end

    describe "#set_first_paid_plan_started_at" do
      it "should be set if site created with paid plan" do
        site = Factory(:site, plan_id: @paid_plan.id)
        site.first_paid_plan_started_at.should be_present
      end

      it "should not be set if site created with dev plan" do
        site = Factory(:site, plan_id: @dev_plan.id)
        site.first_paid_plan_started_at.should be_nil
      end

      it "should be set when first upgrade to paid plan" do
        site = Factory(:site, plan_id: @dev_plan.id)
        site.first_paid_plan_started_at.should be_nil
        site.reload.plan_id = @paid_plan.id
        site.user_attributes = { current_password: "123456" }
        VCR.use_cassette('ogone/visa_payment_generic') { site.save! }
        site.save!
        site.reload.first_paid_plan_started_at.should be_present
      end
    end

  end # Instance Methods

end
