# coding: utf-8
require 'spec_helper'

describe OneTime::User do

  context "with 1 invited and 1 beta user" do
    before(:all) do
      @invited_user = Factory(:user).tap { |u| u.send(:attributes=, { :invitation_token => '123', :invitation_sent_at => Time.now }, false); u.save(:validate => false) }
      @beta_user    = Factory(:user)
    end

    describe ".delete_invited_not_yet_registered_users" do
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
          described_class.delete_invited_not_yet_registered_users
        end

        it "should only delete invited and not yet registered users" do
          User.all.should == [@beta_user]
        end
      end
    end

    describe ".set_remaining_discounted_months" do
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
          described_class.set_remaining_discounted_months
        end

        it "should set remaining_discounted_months to Billing.discounted_months" do
          @invited_user.reload.remaining_discounted_months.should be_nil
          @beta_user.reload.remaining_discounted_months.should == Billing.discounted_months
        end
      end
    end

  end

end