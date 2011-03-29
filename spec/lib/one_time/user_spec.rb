# coding: utf-8
require 'spec_helper'

describe OneTime::User do

  context "with 1 invited and 1 beta user" do
    before(:all) do
      @invited_user = Factory(:user, invitation_token: '123', :invitation_sent_at => Time.now)
      @beta_user    = Factory(:user, invitation_token: nil, created_at: Time.utc(2011,1,1))
      @normal_user  = Factory(:user, invitation_token: nil)
    end

    describe ".archive_invited_not_yet_registered_users" do
      it "should exist 1 registered user and 1 invited user" do
        @invited_user.should be_invited
        @invited_user.should be_persisted
        @invited_user.should_not be_beta

        @beta_user.should_not be_invited
        @beta_user.should be_persisted
        @beta_user.should be_beta

        @normal_user.should_not be_invited
        @normal_user.should be_persisted
        @normal_user.should_not be_beta

        User.all.should =~ [@invited_user, @beta_user, @normal_user]
        User.invited.all.should =~ [@invited_user]
        User.beta.all.should =~ [@beta_user]
      end

      context "actually test the method" do
        before(:each) do
          described_class.archive_invited_not_yet_registered_users
        end

        it "should only archive invited and not yet registered users" do
          @invited_user.reload
          User.all.should =~ [@beta_user, @invited_user, @normal_user]
          User.with_state(:archived).all.should =~ [@invited_user]
          User.beta.all.should =~ [@beta_user]
          User.invited.all.should =~ [@invited_user]
        end
      end
    end

    # not implemented because CampaignMonitor.should failed with method_missing of SettingsLogic
    # describe ".import_all_beta_users_to_campaign_monitor" do
    #   CampaignMonitor.should_receive(:import).with([@beta_user])
    #   described_class.import_all_beta_users_to_campaign_monitor
    # end


    describe ".uniquify_all_empty_cc_alias" do
      it "should set all empty cc_alias" do
        user = Factory(:user)
        user.update_attribute(:cc_alias, nil)
        user.reload.cc_alias.should be_nil
        described_class.uniquify_all_empty_cc_alias
        user.reload.cc_alias.should =~ /^[A-Z0-9]{8}$/
      end
    end

  end

end