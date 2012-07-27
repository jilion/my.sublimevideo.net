require 'spec_helper'

describe SiteModules::Scope, :plans do
  before { @user = create(:user) }

  describe "state" do
    before do
      Site.delete_all
      @site_active    = create(:site, user: @user)
      @site_archived  = create(:site, user: @user, state: "archived", archived_at: Time.utc(2010,2,28))
      @site_suspended = create(:site, user: @user, state: "suspended")
    end

    describe ".active" do
      specify { Site.active.all.should =~ [@site_active] }
    end

    describe ".inactive" do
      specify { Site.inactive.all.should =~ [@site_archived, @site_suspended] }
    end

    describe ".suspended" do
      specify { Site.suspended.all.should =~ [@site_suspended] }
    end

    describe ".archived" do
      specify { Site.archived.all.should =~ [@site_archived] }
    end

    describe ".not_archived" do
      specify { Site.not_archived.all.should =~ [@site_active, @site_suspended] }
    end
  end

  describe "plan" do
    before do
      Site.delete_all
      @site_free1      = create(:site, user: @user, plan_id: @free_plan.id)
      @site_free1.update_attribute(:next_cycle_plan_id, @paid_plan.id)
      @site_free2      = create(:site, user: @user, state: 'archived', plan_id: @free_plan.id)
      @site_sponsored = create(:site, user: @user, plan_id: @paid_plan.id)
      @site_sponsored.sponsor!
      @site_custom    = create(:site, user: @user, plan_id: @custom_plan.token)
      @site_paid      = create(:site, user: @user, plan_id: @paid_plan.id)
      @site_paid.update_attribute(:next_cycle_plan_id, @free_plan.id)
    end

    describe ".in_custom_plan" do
      specify { Site.in_custom_plan.all.should =~ [@site_custom] }
    end

    describe ".in_paid_plan" do
      specify { Site.in_paid_plan.all.should =~ [@site_custom, @site_paid] }
    end

    describe ".in_plan" do
      specify { Site.in_plan('free').all.should eq [@site_free1] }
      specify { Site.in_plan(['sponsored', 'plus']).order(:id).all.should =~ [@site_sponsored, @site_paid] }
    end

    describe ".in_plan_id" do
      specify { Site.in_plan_id(@free_plan.id).all.should eq [@site_free1] }
      specify { Site.in_plan_id([@free_plan.id, @sponsored_plan.id]).all.should =~ [@site_free1, @site_sponsored] }
    end

  end

  describe "attributes queries" do
    before do
      Site.delete_all
      @site_wildcard        = create(:site, user: @user, wildcard: true)
      @site_path            = create(:site, user: @user, path: "foo", path: 'foo')
      @site_extra_hostnames = create(:site, user: @user, extra_hostnames: "foo.com")
      @site_next_cycle_plan = create(:site, user: @user)
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
    before do
      Site.delete_all
      @site_with_no_invoice       = create(:fake_site, user: @user)
      @site_with_paid_invoice     = create(:site, user: @user)
      @site_with_canceled_invoice = create(:site, user: @user)
      @site_with_canceled_invoice.invoices.last.update_attribute(:state, 'canceled')
    end

    describe ".with_not_canceled_invoices" do
      specify { Site.with_not_canceled_invoices.all.should =~ [@site_with_paid_invoice] }
    end
  end

  describe "trial" do
    before do
      Site.delete_all
      @site_in_paid             = create(:fake_site, user: @user, plan_id: @paid_plan.id)
      @site_in_trial            = create(:fake_site, user: @user, plan_id: @trial_plan.id)
      @site_in_trial_ended      = create(:fake_site, user: @user, plan_id: @trial_plan.id, plan_started_at: BusinessModel.days_for_trial.days.ago)
      @site_trial_ends_in_1_day = create(:fake_site, user: @user, plan_id: @trial_plan.id, plan_started_at: (BusinessModel.days_for_trial - 1).days.ago.midnight)
    end

    describe ".in_trial" do
      specify { Site.in_trial.all.should =~ [@site_in_trial, @site_in_trial_ended, @site_trial_ends_in_1_day] }
    end

    describe ".trial_ended" do
      specify { Site.trial_ended.all.should =~ [@site_in_trial_ended] }
    end

    describe ".trial_expires_on" do
      specify { Site.trial_expires_on(2.days.from_now).all.should be_empty }
      specify { Site.trial_expires_on(1.day.from_now).all.should =~ [@site_trial_ends_in_1_day] }
    end
  end

  describe ".renewable" do
    before do
      Site.delete_all
      Timecop.travel(2.months.ago) do
        @site_renewable      = create(:site, user: @user, first_paid_plan_started_at: Time.now.utc)
        @site_suspended      = create(:site, user: @user, state: 'suspended', first_paid_plan_started_at: Time.now.utc)
        @site_archived       = create(:site, user: @user, first_paid_plan_started_at: Time.now.utc)
        @site_archived.user.current_password = '123456'
        @site_archived.archive!
        @site_archived.should be_archived
        @site_not_renewable3 = build(:new_site, user: @user, plan_id: @paid_plan.id, first_paid_plan_started_at: Time.now.utc)
      end
      @site_not_renewable3.pending_plan_id.should eql @paid_plan.id
      @site_not_renewable4 = create(:site_with_invoice, user: @user, plan_started_at: 3.months.ago, plan_cycle_ended_at: 2.months.from_now)
    end

    specify { Site.renewable.all.should =~ [@site_renewable] }
  end

  describe ".refunded" do
    before do
      Site.delete_all
      @site_refunded_1     = create(:site, user: @user, state: 'archived', refunded_at: Time.now.utc)
      @site_not_refunded_1 = create(:site, user: @user, state: 'active', refunded_at: Time.now.utc)
      @site_not_refunded_2 = create(:site, user: @user, state: 'archived', refunded_at: nil)
    end

    specify { Site.refunded.all.should =~ [@site_refunded_1] }
  end

end
