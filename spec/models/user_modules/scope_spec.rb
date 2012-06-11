require 'spec_helper'

describe UserModules::Scope, :plans do

  describe "state" do
    before do
      @user_invited = create(:user, invitation_token: '123', state: 'archived')
      @user_beta    = create(:user, invitation_token: nil, created_at: PublicLaunch.beta_transition_started_on - 1.day, state: 'suspended')
      @user_active  = create(:user)
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
    before do
      @user_no_cc = create(:user, cc_type: nil, cc_last_digits: nil)
      @user_cc    = create(:user, cc_type: 'visa', cc_last_digits: '1234')
    end

    describe ".without_cc" do
      specify { User.without_cc.all.should =~ [@user_no_cc] }
    end

    describe ".with_cc" do
      specify { User.with_cc.all.should =~ [@user_cc] }
    end
  end

  describe "billing" do
    before do
      # Paying because of 1 paid plan not in trial
      @user1 = create(:user)
      create(:site_not_in_trial, user: @user1, plan_id: @paid_plan.id)

      # Paying because of 1 paid plan not in trial (+ next plan is paid)
      @user2 = create(:user)
      create(:site_not_in_trial, user: @user2, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, create(:plan).id)

      # Paying because of 1 paid plan not in trial (+ next plan is free)
      @user3 = create(:user)
      create(:site_not_in_trial, user: @user3, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, @free_plan.id)

      # Free because no paying (and active) sites
      @user4 = create(:user)
      create(:site_not_in_trial, user: @user4, state: 'archived', archived_at: Time.utc(2010,2,28))

      # Free because of no paid plan
      @user5 = create(:user)
      create(:site, user: @user5, plan_id: @free_plan.id)

      # Free because of 1 paid plan in trial
      @user6 = create(:user)
      create(:site, user: @user6, plan_id: @paid_plan.id)

      # Archived and that's it
      @user7 = create(:user, state: 'archived')
      create(:site, user: @user7, plan_id: @paid_plan.id).update_attribute(:next_cycle_plan_id, create(:plan).id)
      @user8 = create(:user, state: 'archived')
    end

    describe ".free" do
      specify { User.free.all.should =~ [@user4, @user5, @user6] }
    end

    describe ".paying" do
      specify { User.paying.all.should =~ [@user1, @user2, @user3] }
    end
  end

  describe ".newsletter" do
    before do
      @user1 = create(:user, newsletter: true)
      @user2 = create(:user, newsletter: false)
    end

    specify { User.newsletter.all.should eq [@user1] }
    specify { User.newsletter(true).all.should eq [@user1] }
    specify { User.newsletter(false).all.should eq [@user2] }
  end

  describe ".search" do
    before do
      @user1 = create(:user, email: "remy@jilion.com", name: "Marcel Jacques")
      @site1 = create(:site, user: @user1, hostname: "bob.com", plan_id: @free_plan.id)
      # THIS IS HUGELY SLOW DUE TO IPAddr.new('*.dev')!!!!!!!
      @site2 = create(:new_site, user: @user1, dev_hostnames: "foo.dev, bar.dev")
      @site3 = create(:new_site, user: @user1, dev_hostnames: "192.168.0.0, 192.168.0.30")
    end

    specify { User.search("remy").all.should eq [@user1] }
    specify { User.search("bob").all.should eq [@user1] }
    specify { User.search(".dev").all.should eq [@user1] }
    specify { User.search("192.168").all.should eq [@user1] }
    specify { User.search("marcel").all.should eq [@user1] }
    specify { User.search("jacques").all.should eq [@user1] }
  end

  describe ".sites_tagged_with" do
    before do
      @user = create(:user).tap { |u| u.tag_list = ['foo']; u.save }
      @site = create(:site, user: @user).tap { |s| s.tag_list = ['bar']; s.save }
    end

    it "returns the user that has a site with the given word" do
      Site.tagged_with('bar').should eq [@site]
      User.sites_tagged_with('bar').should eq [@user]
    end
  end

end
