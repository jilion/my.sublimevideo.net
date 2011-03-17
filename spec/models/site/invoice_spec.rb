require 'spec_helper'

describe Site::Invoice do

  describe ".delay_renew_active_sites" do
    it "should delay renew_active_sites if not already delayed" do
      expect { Site.delay_renew_active_sites }.should change(Delayed::Job.where(:handler.matches => '%Site%renew_active_sites%'), :count).by(1)
    end

    it "should not delay renew_active_sites if already delayed" do
      Site.delay_renew_active_sites
      expect { Site.delay_renew_active_sites }.should change(Delayed::Job.where(:handler.matches => '%Site%renew_active_sites%'), :count).by(0)
    end
  end

  describe ".renew_active_sites" do
    before(:all) do
      Site.delete_all
      @plan1 = Factory(:plan, cycle: "month")
      @plan2 = Factory(:plan, cycle: "month")

      # to be renewed
      Timecop.travel(Time.utc(2010,2,28)) do
        @site1 = Factory(:site, plan: @plan1)
        @site2 = Factory(:site, plan: @plan1, next_cycle_plan: @plan2)
        @site1.plan_cycle_ended_at.should == Time.utc(2010,3,27).to_datetime.end_of_day
        @site2.plan_cycle_ended_at.should == Time.utc(2010,3,27).to_datetime.end_of_day
      end

      # not to be renewed
      Timecop.travel(Time.utc(2010,3,2)) do
        @site3 = Factory(:site, plan: @plan1)
        @site4 = Factory(:site, plan: @plan1, next_cycle_plan: @plan2)
        @site3.plan_cycle_ended_at.should == Time.utc(2010,4,1).to_datetime.end_of_day
        @site4.plan_cycle_ended_at.should == Time.utc(2010,4,1).to_datetime.end_of_day
      end
    end
    before(:each) do
      Delayed::Job.delete_all
      Timecop.travel(Time.utc(2010,3,30,1)) do
        Site.renew_active_sites
      end
    end

    it "should update site that need to be renewed" do
      @site1.reload.plan_cycle_ended_at.should == Time.utc(2010,4,27).to_datetime.end_of_day
      @site2.reload.plan_cycle_ended_at.should == Time.utc(2010,4,27).to_datetime.end_of_day

      @site3.reload.plan_cycle_ended_at.should == Time.utc(2010,4,1).to_datetime.end_of_day
      @site4.reload.plan_cycle_ended_at.should == Time.utc(2010,4,1).to_datetime.end_of_day
    end

    it "should delay renew_active_sites" do
      Delayed::Job.where(:handler.matches => '%Site%renew_active_sites%').count.should == 1
    end

  end # .renew_active_sites

  describe "#update_cycle_plan" do
    before(:all) do
      @paid_plan         = Factory(:plan, cycle: "month", price: 1000)
      @paid_plan2        = Factory(:plan, cycle: "month", price: 5000)
      @paid_plan_yearly  = Factory(:plan, cycle: "year",  price: 10000)
      @paid_plan_yearly2 = Factory(:plan, cycle: "year",  price: 50000)
    end

    context "new site with dev plan" do

      describe "on creation" do
        before(:all) { Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @dev_plan) } }
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should be_nil }
        its(:plan_cycle_ended_at)   { should be_nil }
        its(:plan)                  { should == @dev_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should be_instant_charging }
      end

      describe "when update_cycle_plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @dev_plan) }
          Timecop.travel(Time.utc(2011,3,3))  { @site.reload.update_cycle_plan }
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should be_nil }
        its(:plan_cycle_ended_at)   { should be_nil }
        its(:plan)                  { should == @dev_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end

      describe "when upgrade to monthly paid plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @dev_plan) }
          Timecop.travel(Time.utc(2011,2,10)) { @site.reload.update_attributes(plan_id: @paid_plan.id) }
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,2,10).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,2,10).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2011,3,9).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should be_instant_charging }
      end

      describe "when upgrade to yearly paid plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @dev_plan) }
          Timecop.travel(Time.utc(2011,5,15)) { subject.reload.update_attributes(plan_id: @paid_plan_yearly.id) }
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,5,15).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,5,15).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2012,5,14).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan_yearly }
        its(:next_cycle_plan)       { should be_nil }
        it { should be_instant_charging }
      end
    end

    context "new site with monthly paid plan" do

      describe "on creation" do
        before(:all) { Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan) } }
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2011,2,27).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should be_instant_charging }
      end

      describe "when update_cycle_plan (same cycle)" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan) }
          Timecop.travel(Time.utc(2011,2,5))  { @site.reload.update_cycle_plan }
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2011,2,27).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end

      describe "when update_cycle_plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan) }
          Timecop.travel(Time.utc(2011,3,3))  { @site.reload.update_cycle_plan }
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,2,28).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2011,3,29).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end

      describe "when upgrade to monthly paid plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan) }
          Timecop.travel(Time.utc(2011,3,3))  { @site.reload.update_cycle_plan; @site.save }
          Timecop.travel(Time.utc(2011,3,10)) do
            @site.reload.update_attributes(
              plan_id: @paid_plan2.id,
              user_attributes: { current_password: '123456' }
            )
          end
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,2,28).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,2,28).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2011,3,27).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan2 }
        its(:next_cycle_plan)       { should be_nil }
        it { should be_instant_charging }
      end

      describe "when upgrade to yearly paid plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan) }
          Timecop.travel(Time.utc(2011,2,10)) do
            @site.reload.update_attributes(
              plan_id: @paid_plan_yearly.id,
              user_attributes: { current_password: '123456' }
            )
          end
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2012,1,29).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan_yearly }
        its(:next_cycle_plan)       { should be_nil }
        it { should be_instant_charging }
      end

      describe "when downgrade to dev plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan) }
          Timecop.travel(Time.utc(2011,3,1)) do
            @site.update_cycle_plan
            @site.reload.update_attributes(
              plan_id: @dev_plan.id, # will set next_cycle_plan_id
              user_attributes: { current_password: '123456' }
            )
            @site.reload.update_cycle_plan
          end
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,2,28).midnight }
        its(:plan_cycle_started_at) { should be_nil }
        its(:plan_cycle_ended_at)   { should be_nil }
        its(:plan)                  { should == @dev_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end

      describe "when downgrade to monthly paid plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan2) }
          Timecop.travel(Time.utc(2011,3,3))  { @site.reload.update_cycle_plan; @site.save }
          Timecop.travel(Time.utc(2011,4,1)) do
            @site.reload.update_attributes(
              plan_id: @paid_plan.id, # will set next_cycle_plan_id
              user_attributes: { current_password: '123456' }
            )
            @site.reload.update_cycle_plan
          end
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,3,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,3,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2011,4,29).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end

    end

    context "new site with yearly paid plan" do

      describe "on creation" do
        before(:all) { Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan_yearly) } }
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2012,1,29).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan_yearly }
        its(:next_cycle_plan)       { should be_nil }
        it { should be_instant_charging }
      end

      describe "when update_cycle_plan (same cycle)" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan_yearly) }
          Timecop.travel(Time.utc(2011,5,5))  { @site.reload.update_cycle_plan }
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2012,1,29).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan_yearly }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end

      describe "when update_cycle_plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan_yearly) }
          Timecop.travel(Time.utc(2012,2,1))  { @site.reload.update_cycle_plan }
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2012,1,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2013,1,29).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan_yearly }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end

      describe "when upgrade to yearly paid plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan_yearly) }
          Timecop.travel(Time.utc(2011,2,10)) do
            @site.reload.update_attributes(
              plan_id: @paid_plan_yearly2.id,
              user_attributes: { current_password: '123456' }
            )
          end
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2011,1,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2012,1,29).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan_yearly2 }
        its(:next_cycle_plan)       { should be_nil }
        it { should be_instant_charging }
      end

      describe "when downgrade to dev plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan_yearly) }
          Timecop.travel(Time.utc(2012,2,1)) do
            @site.reload.update_attributes(
              plan_id: @dev_plan.id, # will set next_cycle_plan_id
              user_attributes: { current_password: '123456' }
            )
            @site.reload.update_cycle_plan
          end
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2012,1,30).midnight }
        its(:plan_cycle_started_at) { should be_nil }
        its(:plan_cycle_ended_at)   { should be_nil }
        its(:plan)                  { should == @dev_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end

      describe "when downgrade to yearly paid plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan_yearly) }
          Timecop.travel(Time.utc(2012,2,1)) do
            @site.reload.update_attributes(
              plan_id: @paid_plan_yearly2.id, # will set next_cycle_plan_id
              user_attributes: { current_password: '123456' }
            )
            @site.reload.update_cycle_plan
          end
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2012,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2012,1,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2013,1,29).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan_yearly2 }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end

      describe "when downgrade to monthly paid plan" do
        before(:all) do
          Timecop.travel(Time.utc(2011,1,30)) { @site = Factory(:site, plan: @paid_plan_yearly) }
          Timecop.travel(Time.utc(2012,2,1))  { @site.reload.update_cycle_plan; @site.save }
          Timecop.travel(Time.utc(2013,2,1)) do
            @site.reload.update_attributes(
              plan_id: @paid_plan.id, # will set next_cycle_plan_id
              user_attributes: { current_password: '123456' }
            )
            @site.reload.update_cycle_plan
          end
        end
        subject { @site }

        its(:plan_started_at)       { should == Time.utc(2013,1,30).midnight }
        its(:plan_cycle_started_at) { should == Time.utc(2013,1,30).midnight }
        its(:plan_cycle_ended_at)   { should == Time.utc(2013,2,27).to_datetime.end_of_day }
        its(:plan)                  { should == @paid_plan }
        its(:next_cycle_plan)       { should be_nil }
        it { should_not be_instant_charging }
      end
    end
  end

  describe "#months_since" do
    before(:all) { @site = Factory.build(:site) }

    context "with plan_started_at 2011,1,1" do
      before(:all) { @site.plan_started_at = Time.utc(2011,1,1) }

      specify { Timecop.travel(Time.utc(2011,1,1)) { @site.months_since(nil).should == 0 } }
      specify { Timecop.travel(Time.utc(2011,1,1)) { @site.months_since(@site.plan_started_at).should == 0 } }
      specify { Timecop.travel(Time.utc(2011,1,31)) { @site.months_since(@site.plan_started_at).should == 0 } }
      specify { Timecop.travel(Time.utc(2011,2,1)) { @site.months_since(@site.plan_started_at).should == 1 } }
      specify { Timecop.travel(Time.utc(2011,2,15)) { @site.months_since(@site.plan_started_at).should == 1 } }
      specify { Timecop.travel(Time.utc(2011,2,28)) { @site.months_since(@site.plan_started_at).should == 1 } }
      specify { Timecop.travel(Time.utc(2012,1,1)) { @site.months_since(@site.plan_started_at).should == 12 } }
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

  describe "#advance_for_next_cycle_end" do
    context "with a monthly plan" do
      before(:all) do
        @plan = Factory(:plan, cycle: "month")
        @site = Factory(:site)
        @site.plan_started_at.should == Time.now.utc.midnight
      end

      context "when now is less than 1 month after site.plan_started_at" do
        it "should return 0 year + 1 month in advance - 1 day" do
          Timecop.travel(Time.now.utc.midnight + 1.day) do
            @site.send(:advance_for_next_cycle_end, @plan).should == 1.month - 1.day
          end
        end
      end

      1.upto(13) do |i|
        context "when now is #{i} months after site.plan_started_at" do
          it "should return #{i} + 1 months in advance - 1 day" do
            Timecop.travel(Time.now.utc.midnight + i.months + 1.day) do
              @site.send(:advance_for_next_cycle_end, @plan).should == (i + 1).months - 1.day
            end
          end
        end
      end
    end

    context "with a yearly plan" do
      before(:all) do
        @plan = Factory(:plan, cycle: "year")
        @site = Factory(:site)
        @site.plan_started_at.should == Time.now.utc.midnight
      end

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

  end

end
