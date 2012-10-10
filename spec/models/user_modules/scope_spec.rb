# coding: utf-8
require 'spec_helper'

describe UserModules::Scope do

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
      @user_no_cc        = create(:user, cc_type: nil, cc_last_digits: nil)
      @user_cc           = create(:user, cc_type: 'visa', cc_last_digits: '1234')
      @user_cc_expire_on = create(:user, cc_expire_on: Time.now.utc.end_of_month.to_date)
    end

    describe ".without_cc" do
      specify { User.without_cc.all.should =~ [@user_no_cc] }
    end

    describe ".with_cc" do
      specify { User.with_cc.all.should =~ [@user_cc, @user_cc_expire_on] }
    end

    describe ".cc_expire_this_month" do
      specify { User.cc_expire_this_month.all.should =~ [@user_cc_expire_on] }
    end
  end

  describe "billing", :addons do
    let(:site1) { create(:site) }
    let(:site2) { create(:site) }
    let(:site3) { create(:site) }
    let(:site4) { create(:site, user: create(:user, state: 'suspended')) }
    let(:site5) { create(:site, user: create(:user, state: 'archived')) }
    let(:site6) { create(:site) }
    before do
      create(:billable_item, site: site1, item: create(:addon_plan, price: 995), state: 'beta')
      create(:billable_item, site: site2, item: create(:addon_plan, price: 995), state: 'trial')
      create(:billable_item, site: site3, item: create(:addon_plan, price: 995), state: 'sponsored')
      create(:billable_item, site: site4, item: create(:addon_plan, price: 995), state: 'suspended')
      create(:billable_item, site: site5, item: create(:addon_plan, price: 995), state: 'subscribed')
      create(:billable_item, site: site6, item: create(:addon_plan, price: 995), state: 'subscribed')
    end

    describe ".free" do
      specify { User.free.all.should =~ [site1.user, site2.user, site3.user] }
    end

    describe ".paying" do
      specify { User.paying.all.should =~ [site6.user] }
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

  describe ".created_on" do
    before do
      @user1 = create(:user, created_at: 3.days.ago)
      @user2 = create(:user, created_at: 2.days.ago)
    end

    specify { User.created_on(3.days.ago).all.should eq [@user1] }
    specify { User.created_on(2.days.ago).all.should eq [@user2] }
  end

  describe ".search" do
    before do
      @user1 = create(:user, email: "remy@jilion.com", name: "Marcel Jacques")
      create(:site, user: @user1, hostname: "bob.com")
      # THIS IS HUGELY SLOW DUE TO IPAddr.new('*.dev')!!!!!!!
      # create(:site, user: @user1, dev_hostnames: "foo.dev, bar.dev")
      create(:site, user: @user1, dev_hostnames: "192.168.0.0, 192.168.0.30")
    end

    specify { User.search("remy").all.should eq [@user1] }
    specify { User.search("bob").all.should eq [@user1] }
    # specify { User.search(".dev").all.should eq [@user1] }
    specify { User.search("192.168").all.should eq [@user1] }
    specify { User.search("marcel").all.should eq [@user1] }
    specify { User.search("jacques").all.should eq [@user1] }
  end

  describe ".sites_tagged_with" do
    before do
      @user = create(:user).tap { |u| u.tag_list = ['foo']; u.save! }
      @site = create(:site, user: @user).tap { |s| s.tag_list = ['bar']; s.save! }
    end

    it "returns the user that has a site with the given word" do
      Site.tagged_with('bar').should eq [@site]
      User.sites_tagged_with('bar').should eq [@user]
    end
  end

end
