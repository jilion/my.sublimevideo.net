require 'spec_helper'

describe SiteModules::Scope do

  before(:all) do
    @user = Factory.create(:user)
  end

  describe "state" do
    before(:all) do
      Site.delete_all
      @site_active    = Factory.create(:site, user: @user)
      @site_archived  = Factory.create(:site, user: @user, state: "archived", archived_at: Time.utc(2010,2,28))
      @site_suspended = Factory.create(:site, user: @user, state: "suspended")
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
      @site_free      = Factory.create(:site, user: @user, plan_id: @free_plan.id)
      @site_sponsored = Factory.create(:site, user: @user, plan_id: @paid_plan.id)
      @site_sponsored.sponsor!
      @site_custom    = Factory.create(:site, user: @user, plan_id: @custom_plan.token)
      @site_paid      = Factory.create(:site, user: @user, plan_id: @paid_plan.id)
    end

    describe ".custom" do
      specify { Site.in_custom_plan.all.should =~ [@site_custom] }
    end

    describe ".in_paid_plan" do
      specify { Site.in_paid_plan.all.should =~ [@site_custom, @site_paid] }
    end

    describe ".in_plan" do
      specify { Site.in_plan('free').all.should eq [@site_free] }
      specify { Site.in_plan('sponsored').all.should eq [@site_sponsored] }
      specify { Site.in_plan('plus').all.should eq [@site_paid] }
    end
  end

  describe "attributes queries" do
    before(:all) do
      Site.delete_all
      @site_wildcard        = Factory.create(:site, user: @user, wildcard: true)
      @site_path            = Factory.create(:site, user: @user, path: "foo", path: 'foo')
      @site_extra_hostnames = Factory.create(:site, user: @user, extra_hostnames: "foo.com")
      @site_next_cycle_plan = Factory.create(:site, user: @user)
      @site_next_cycle_plan.update_attribute(:next_cycle_plan_id, @free_plan.id)
    end

    describe ".with_wildcard" do
      specify { Site.with_wildcard.all.should =~ [@site_wildcard] }
    end

    describe ".with_path" do
      specify { Site.with_path.all.should =~ [@site_path] }
    end

    describe ".with_extra_hostnames" do
      specify { Site.with_extra_hostnames.all.should =~ [@site_extra_hostnames] }
    end

    describe ".with_next_cycle_plan" do
      specify { Site.with_next_cycle_plan.all.should =~ [@site_next_cycle_plan] }
    end
  end

  describe "invoices" do
    before(:all) do
      Site.delete_all
      @site_with_no_invoice = Factory.create(:site, user: @user)
      @site_with_paid_invoice = Factory.create(:site_with_invoice, user: @user)
      @site_with_canceled_invoice = Factory.create(:site_with_invoice, user: @user)
      @site_with_canceled_invoice.invoices.last.update_attribute(:state, 'canceled')
    end

    describe ".with_not_canceled_invoices" do
      specify { Site.with_not_canceled_invoices.all.should =~ [@site_with_paid_invoice] }
    end
  end

  describe "billing" do
    before(:all) do
      Site.delete_all
      # billable
      @site_billable     = Factory.create(:site, user: @user, plan_id: @paid_plan.id)
      @site_will_be_paid = Factory.create(:site, user: @user, plan_id: @paid_plan.id)
      @site_will_be_paid.update_attribute(:next_cycle_plan_id, Factory.create(:plan).id)

      # not billable
      @site_free         = Factory.create(:site, user: @user, plan_id: @free_plan.id)
      @site_will_be_free = Factory.create(:site, user: @user, plan_id: @paid_plan.id)
      @site_will_be_free.update_attribute(:next_cycle_plan_id, @free_plan.id)
      @site_archived    = Factory.create(:site, user: @user, state: "archived", archived_at: Time.utc(2010,2,28))
      @site_suspended   = Factory.create(:site, user: @user, state: "suspended")
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
      @site_not_in_trial = Factory.create(:site, user: @user, trial_started_at: BusinessModel.days_for_trial.days.ago.midnight)
      @site_trial_ends_in_1_day = Factory.create(:site, user: @user, trial_started_at: (BusinessModel.days_for_trial - 1).days.ago.midnight)
    end

    describe "#in_trial" do
      specify { Site.in_trial.all.should =~ [@site_trial_ends_in_1_day] }
    end

    describe "#not_in_trial" do
      specify { Site.not_in_trial.all.should =~ [@site_not_in_trial] }
    end

    describe "#trial_expires_on" do
      specify { Site.trial_expires_on(2.days.from_now).all.should be_empty }
      specify { Site.trial_expires_on(1.day.from_now).all.should =~ [@site_trial_ends_in_1_day] }
    end
  end

  describe "#renewable" do
    before(:all) do
      Site.delete_all
      Timecop.travel(2.months.ago) do
        @site_renewable      = Factory.create(:site_not_in_trial, user: @user, first_paid_plan_started_at: Time.now.utc)
        @site_suspended      = Factory.create(:site_not_in_trial, user: @user, state: 'suspended', first_paid_plan_started_at: Time.now.utc)
        @site_archived       = Factory.create(:site_with_invoice, user: @user, first_paid_plan_started_at: Time.now.utc)
        @site_archived.user.current_password = '123456'
        @site_archived.archive!
        @site_archived.should be_archived
        @site_not_renewable3 = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id, first_paid_plan_started_at: Time.now.utc)
      end
      @site_not_renewable3.pending_plan_id.should eql @paid_plan.id
      @site_not_renewable4 = Factory.create(:site_with_invoice, user: @user, plan_started_at: 3.months.ago, plan_cycle_ended_at: 2.months.from_now)
    end

    specify { Site.renewable.all.should =~ [@site_renewable] }
  end

  describe "#refundable" do
    before(:all) do
      Site.delete_all
      @site_refundable = Factory.create(:site, user: @user, first_paid_plan_started_at: (BusinessModel.days_for_refund-1).days.ago)
      @site_not_refundable1 = Factory.create(:site, user: @user, first_paid_plan_started_at: (BusinessModel.days_for_refund+1).days.ago)
      @site_not_refundable2 = Factory.create(:site, user: @user, refunded_at: Time.now.utc)
    end

    specify { Site.refundable.all.should =~ [@site_refundable] }
  end

  describe "#refunded" do
    before(:all) do
      Site.delete_all
      @site_refunded_1     = Factory.create(:site, user: @user, state: 'archived', refunded_at: Time.now.utc)
      @site_not_refunded_1 = Factory.create(:site, user: @user, state: 'active', refunded_at: Time.now.utc)
      @site_not_refunded_2 = Factory.create(:site, user: @user, state: 'archived', refunded_at: nil)
    end

    specify { Site.refunded.all.should =~ [@site_refunded_1] }
  end

end
