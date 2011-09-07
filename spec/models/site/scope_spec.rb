require 'spec_helper'

describe Site::Scope do

  before(:all) do
    @user = FactoryGirl.create(:user)
  end

  describe "state" do
    before(:all) do
      Site.delete_all
      @site_active    = FactoryGirl.create(:site, user: @user)
      @site_archived  = FactoryGirl.create(:site, user: @user, state: "archived", archived_at: Time.utc(2010,2,28))
      @site_suspended = FactoryGirl.create(:site, user: @user, state: "suspended")
    end

    describe "#active" do
      specify { Site.active.all.should =~ [@site_active] }
    end

    describe "#inactive" do
      specify { Site.inactive.all.should =~ [@site_archived, @site_suspended] }
    end

    describe "#suspended" do
      specify { Site.suspended.all.should =~ [@site_suspended] }
    end

    describe "#archived" do
      specify { Site.archived.all.should =~ [@site_archived] }
    end

    describe "#not_archived" do
      specify { Site.not_archived.all.should =~ [@site_active, @site_suspended] }
    end
  end

  describe "plan" do
    before(:all) do
      Site.delete_all
      @site_free       = FactoryGirl.create(:site, user: @user, plan_id: @free_plan.id)
      @site_sponsored = FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
      @site_sponsored.sponsor!
      @site_custom    = FactoryGirl.create(:site, user: @user, plan_id: @custom_plan.token)
      @site_paid      = FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
    end

    describe "#free" do
      specify { Site.free.all.should =~ [@site_free] }
    end

    describe "#sponsored" do
      specify { Site.sponsored.all.should =~ [@site_sponsored] }
    end

    describe "#custom" do
      specify { Site.custom.all.should =~ [@site_custom] }
    end

    describe "#in_paid_plan" do
      specify { Site.in_paid_plan.all.should =~ [@site_custom, @site_paid] }
    end
  end

  describe "attributes queries" do
    before(:all) do
      Site.delete_all
      @site_wildcard        = FactoryGirl.create(:site, user: @user, wildcard: true)
      @site_path            = FactoryGirl.create(:site, user: @user, path: "foo", path: 'foo')
      @site_extra_hostnames = FactoryGirl.create(:site, user: @user, extra_hostnames: "foo.com")
      @site_next_cycle_plan = FactoryGirl.create(:site, user: @user)
      @site_next_cycle_plan.update_attribute(:next_cycle_plan_id, @free_plan.id)
    end

    describe "#with_wildcard" do
      specify { Site.with_wildcard.all.should =~ [@site_wildcard] }
    end

    describe "#with_path" do
      specify { Site.with_path.all.should =~ [@site_path] }
    end

    describe "#with_extra_hostnames" do
      specify { Site.with_extra_hostnames.all.should =~ [@site_extra_hostnames] }
    end

    describe "#with_next_cycle_plan" do
      specify { Site.with_next_cycle_plan.all.should =~ [@site_next_cycle_plan] }
    end
  end

  describe "billing" do
    before(:all) do
      Site.delete_all
      # billable
      @site_billable     = FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
      @site_will_be_paid = FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
      @site_will_be_paid.update_attribute(:next_cycle_plan_id, FactoryGirl.create(:plan).id)

      # not billable
      @site_free         = FactoryGirl.create(:site, user: @user, plan_id: @free_plan.id)
      @site_will_be_free = FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
      @site_will_be_free.update_attribute(:next_cycle_plan_id, @free_plan.id)
      @site_archived    = FactoryGirl.create(:site, user: @user, state: "archived", archived_at: Time.utc(2010,2,28))
      @site_suspended   = FactoryGirl.create(:site, user: @user, state: "suspended")
    end

    describe "#billable" do
      specify { Site.billable.all.should =~ [@site_billable, @site_will_be_paid] }
    end

    describe "#not_billable" do
      specify { Site.not_billable.all.should =~ [@site_free, @site_will_be_free, @site_archived, @site_suspended] }
    end
  end

  describe "trial" do
    before(:all) do
      Site.delete_all
      @site_not_in_trial = FactoryGirl.create(:site, user: @user, trial_started_at: BusinessModel.days_for_trial.days.ago)
      @site_trial_ends_in_8_days = FactoryGirl.create(:site, user: @user, trial_started_at: (BusinessModel.days_for_trial - 8).days.ago)
      @site_trial_ends_in_3_days = FactoryGirl.create(:site, user: @user, trial_started_at: (BusinessModel.days_for_trial - 3).days.ago)
      @site_trial_ends_in_1_day  = FactoryGirl.create(:site, user: @user, trial_started_at: (BusinessModel.days_for_trial - 1).days.ago)
    end

    describe "#in_trial" do
      specify { Site.in_trial.all.should =~ [@site_trial_ends_in_8_days, @site_trial_ends_in_3_days, @site_trial_ends_in_1_day] }
    end

    describe "#not_in_trial" do
      specify { Site.not_in_trial.all.should =~ [@site_not_in_trial] }
    end

    describe "#trial_ended_in" do
      specify { Site.trial_ended_in(5.days).all.should =~ [@site_not_in_trial, @site_trial_ends_in_3_days, @site_trial_ends_in_1_day] }
      specify { Site.trial_ended_in(2.days).all.should =~ [@site_not_in_trial, @site_trial_ends_in_1_day] }
      specify { Site.trial_ended_in(1.day - 1.minute).all.should =~ [@site_not_in_trial] }
    end
  end

  describe "#renewable" do
    before(:all) do
      Site.delete_all
      Timecop.travel(2.months.ago) do
        @site_renewable      = FactoryGirl.create(:site_not_in_trial, user: @user, first_paid_plan_started_at: Time.now.utc)
        @site_suspended      = FactoryGirl.create(:site_not_in_trial, user: @user, state: 'suspended', first_paid_plan_started_at: Time.now.utc)
        @site_archived       = FactoryGirl.create(:site_with_invoice, user: @user, first_paid_plan_started_at: Time.now.utc)
        @site_archived.user.current_password = '123456'
        @site_archived.archive!
        @site_archived.should be_archived
        @site_not_renewable3 = FactoryGirl.build(:new_site, user: @user, plan_id: @paid_plan.id, first_paid_plan_started_at: Time.now.utc)
      end
      @site_not_renewable3.pending_plan_id.should eql @paid_plan.id
      @site_not_renewable4 = FactoryGirl.create(:site_with_invoice, user: @user, plan_started_at: 3.months.ago, plan_cycle_ended_at: 2.months.from_now)
    end

    specify { Site.renewable.all.should =~ [@site_renewable] }
  end

  describe "#refundable" do
    before(:all) do
      Site.delete_all
      @site_refundable = FactoryGirl.create(:site, user: @user, first_paid_plan_started_at: (BusinessModel.days_for_refund-1).days.ago)
      @site_not_refundable1 = FactoryGirl.create(:site, user: @user, first_paid_plan_started_at: (BusinessModel.days_for_refund+1).days.ago)
      @site_not_refundable2 = FactoryGirl.create(:site, user: @user, refunded_at: Time.now.utc)
    end

    specify { Site.refundable.all.should =~ [@site_refundable] }
  end

  describe "#refunded" do
    before(:all) do
      Site.delete_all
      @site_refunded_1     = FactoryGirl.create(:site, user: @user, state: 'archived', refunded_at: Time.now.utc)
      @site_not_refunded_1 = FactoryGirl.create(:site, user: @user, state: 'active', refunded_at: Time.now.utc)
      @site_not_refunded_2 = FactoryGirl.create(:site, user: @user, state: 'archived', refunded_at: nil)
    end

    specify { Site.refunded.all.should =~ [@site_refunded_1] }
  end

end
