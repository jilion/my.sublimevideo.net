# coding: utf-8
require 'spec_helper'

describe OneTime::User do

  context "with 1 invited and 1 beta user" do
    before(:all) do
      @invited_user = Factory(:user).tap { |u| u.send(:attributes=, { :invitation_token => '123', :invitation_sent_at => Time.now }, false); u.save(:validate => false) }
      @beta_user    = Factory(:user)
    end

    describe ".archive_invited_not_yet_registered_users" do
      it "should exist 1 registered user and 1 invited user" do
        @invited_user.should be_invited
        @invited_user.should be_persisted

        @beta_user.should_not be_invited
        @beta_user.should be_persisted

        User.all.should == [@invited_user, @beta_user]
        User.invited.all.should == [@invited_user]
        User.beta.all.should == [@beta_user]
      end

      context "actually test the method" do
        before(:each) do
          described_class.archive_invited_not_yet_registered_users
        end

        it "should only archive invited and not yet registered users" do
          @invited_user.reload
          User.all.should == [@beta_user, @invited_user]
          User.with_state(:archived).all.should == [@invited_user]
          User.beta.all.should == [@beta_user]
          User.invited.all.should == [@invited_user]
        end
      end
    end

    # not implemented because CampaignMonitor.should failed with method_missing of SettingsLogic
    # describe ".import_all_beta_users_to_campaign_monitor" do
    #   CampaignMonitor.should_receive(:import).with([@beta_user])
    #   described_class.import_all_beta_users_to_campaign_monitor
    # end

  end

end