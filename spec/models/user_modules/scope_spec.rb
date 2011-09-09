require 'spec_helper'

describe UserModules::Scope do

  describe "state" do
    before(:all) do
      User.delete_all
      @user_invited = FactoryGirl.create(:user, invitation_token: '123', state: 'archived')
      @user_beta    = FactoryGirl.create(:user, invitation_token: nil, created_at: PublicLaunch.beta_transition_started_on - 1.day, state: 'suspended')
      @user_active  = FactoryGirl.create(:user)
    end

    describe "#invited" do
      specify { User.invited.all.should =~ [@user_invited] }
    end

    describe "#beta" do
      specify { User.beta.all.should =~ [@user_beta] }
    end

    describe "#active" do
      specify { User.active.all.should =~ [@user_active] }
    end
  end

  describe "credit card" do
    before(:all) do
      User.delete_all
      @user_no_cc = FactoryGirl.create(:user, cc_type: nil, cc_last_digits: nil)
      @user_cc    = FactoryGirl.create(:user, cc_type: 'visa', cc_last_digits: '1234')
    end

    describe "#without_cc" do
      specify { User.without_cc.all.should =~ [@user_no_cc] }
    end

    describe "#with_cc" do
      specify { User.with_cc.all.should =~ [@user_cc] }
    end
  end

  describe "billing" do
    before(:all) do
      User.delete_all
      # Billable because of 1 paid plan
      @user1 = FactoryGirl.create(:user)
      FactoryGirl.create(:site, user: @user1, plan_id: @paid_plan.id)
      FactoryGirl.create(:site, user: @user1, plan_id: @paid_plan.id)
      FactoryGirl.create(:site, user: @user1, plan_id: @free_plan.id)

      # Billable because next cycle plan is another paid plan
      @user2 = FactoryGirl.create(:user)
      FactoryGirl.create(:site, user: @user2, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, FactoryGirl.create(:plan).id)

      # Not billable because next cycle plan is the free plan
      @user3 = FactoryGirl.create(:user)
      FactoryGirl.create(:site, user: @user3, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, @free_plan.id)

      # Not billable because his site has been archived
      @user4 = FactoryGirl.create(:user)
      FactoryGirl.create(:site, user: @user4, state: 'archived', archived_at: Time.utc(2010,2,28))

      # Billable because next cycle plan is another paid plan, but not active
      @user5 = FactoryGirl.create(:user)
      FactoryGirl.create(:site, user: @user5, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, FactoryGirl.create(:plan).id)

      # Not billable nor active
      @user6 = FactoryGirl.create(:user, state: 'archived')
    end

    describe ".billable" do
      specify { User.billable.all.should =~ [@user1, @user2, @user5] }
    end

    describe ".not_billable" do
      specify { User.not_billable.all.should =~ [@user3, @user4, @user6] }
    end

    describe ".active_and_billable" do
      specify { User.active_and_billable.all.should =~ [@user1, @user2, @user5] }
    end

    describe ".active_and_not_billable" do
      specify { User.active_and_not_billable.all.should =~ [@user3, @user4] }
    end
  end

  describe ".search" do
    before(:all) do
      User.delete_all
      Site.delete_all
      @user1 = FactoryGirl.create(:user, email: "remy@jilion.com", first_name: "Marcel", last_name: "Jacques")
      @site1 = FactoryGirl.create(:site, user: @user1, hostname: "bob.com", plan_id: @free_plan.id)
      # THIS IS HUGELY SLOW DUE TO IPAddr.new('*.dev')!!!!!!!
      # @site2 = FactoryGirl.create(:new_site, user: @user1, dev_hostnames: "foo.dev, bar.dev")
      @site2 = FactoryGirl.create(:new_site, user: @user1, dev_hostnames: "192.168.0.0, 192.168.0.30")
    end

    specify { User.search("remy").all.should =~ [@user1] }
    specify { User.search("bob").all.should =~ [@user1] }
    specify { User.search("192.168").all.should =~ [@user1] }
    specify { User.search("marcel").all.should =~ [@user1] }
    specify { User.search("jacques").all.should =~ [@user1] }
  end

end
