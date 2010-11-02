# coding: utf-8
require 'spec_helper'

describe OneTime::User do
  
  describe ".delete_invited_not_yet_registered_users" do
    before(:all) do
      @registered_user = Factory(:user)
      @invited_user = Factory(:user).tap { |u| u.send(:attributes=, { :invitation_token => '123', :invitation_sent_at => Time.now }, false); u.save(:validate => false) }
    end
    
    it "should exist 1 registered user and 1 invited user" do
      @registered_user.should_not be_invited
      @registered_user.should be_persisted
      
      @invited_user.should be_invited
      @invited_user.should be_persisted
      
      User.all.should == [@registered_user, @invited_user]
    end
    
    context "actually test the method" do
      before(:all) do
        described_class.delete_invited_not_yet_registered_users
      end
      
      it "should only delete invited and not yet registered users" do
        User.all.should == [@registered_user]
      end
    end
  end
  
end