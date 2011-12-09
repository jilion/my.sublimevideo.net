require 'spec_helper'

describe UserModules::Scope do

  describe "state" do
    before(:all) do
      User.delete_all
      @user_invited = Factory.create(:user, invitation_token: '123', state: 'archived')
      @user_beta    = Factory.create(:user, invitation_token: nil, created_at: PublicLaunch.beta_transition_started_on - 1.day, state: 'suspended')
      @user_active  = Factory.create(:user)
    end

    describe ".invited" do
      specify { User.invited.all.should =~ [@user_invited] }
    end

    describe ".beta" do
      specify { User.beta.all.should =~ [@user_beta] }
    end

    describe ".active" do
      specify { User.active.all.should =~ [@user_active] }
    end
  end

  describe "credit card" do
    before(:all) do
      User.delete_all
      @user_no_cc = Factory.create(:user, cc_type: nil, cc_last_digits: nil)
      @user_cc    = Factory.create(:user, cc_type: 'visa', cc_last_digits: '1234')
    end

    describe ".without_cc" do
      specify { User.without_cc.all.should =~ [@user_no_cc] }
    end

    describe ".with_cc" do
      specify { User.with_cc.all.should =~ [@user_cc] }
    end
  end

  describe "billing" do
    before(:all) do
      User.delete_all
      # Paying because of 1 paid plan not in trial
      @user1 = Factory.create(:user)
      Factory.create(:site_not_in_trial, user: @user1, plan_id: @paid_plan.id)

      # Paying because of 1 paid plan not in trial (+ next plan is paid)
      @user2 = Factory.create(:user)
      Factory.create(:site_not_in_trial, user: @user2, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, Factory.create(:plan).id)

      # Paying because of 1 paid plan not in trial (+ next plan is free)
      @user3 = Factory.create(:user)
      Factory.create(:site_not_in_trial, user: @user3, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, @free_plan.id)

      # Free because no paying (and active) sites
      @user4 = Factory.create(:user)
      Factory.create(:site_not_in_trial, user: @user4, state: 'archived', archived_at: Time.utc(2010,2,28))

      # Free because of no paid plan
      @user5 = Factory.create(:user)
      Factory.create(:site, user: @user5, plan_id: @free_plan.id)

      # Free because of 1 paid plan in trial
      @user6 = Factory.create(:user)
      Factory.create(:site, user: @user6, plan_id: @paid_plan.id)

      # Archived and that's it
      @user7 = Factory.create(:user, state: 'archived')
      Factory.create(:site, user: @user7, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, Factory.create(:plan).id)
      @user8 = Factory.create(:user, state: 'archived')
    end

    describe ".free" do
      specify { User.free.all.should =~ [@user4, @user5, @user6] }
    end

    describe ".paying" do
      specify { User.paying.all.should =~ [@user1, @user2, @user3] }
    end
  end

  describe ".search" do
    before(:all) do
      User.delete_all
      Site.delete_all
      @user1 = Factory.create(:user, email: "remy@jilion.com", name: "Marcel Jacques")
      @site1 = Factory.create(:site, user: @user1, hostname: "bob.com", plan_id: @free_plan.id)
      # THIS IS HUGELY SLOW DUE TO IPAddr.new('*.dev')!!!!!!!
      # @site2 = Factory.create(:new_site, user: @user1, dev_hostnames: "foo.dev, bar.dev")
      @site2 = Factory.create(:new_site, user: @user1, dev_hostnames: "192.168.0.0, 192.168.0.30")
    end

    specify { User.search("remy").all.should =~ [@user1] }
    specify { User.search("bob").all.should =~ [@user1] }
    specify { User.search("192.168").all.should =~ [@user1] }
    specify { User.search("marcel").all.should =~ [@user1] }
    specify { User.search("jacques").all.should =~ [@user1] }
  end

end
