# == Schema Information
#
# Table name: users
#
#  trial_ended_at                        :datetime
#  trial_usage_information_email_sent_at :datetime
#  trial_usage_warning_email_sent_at     :datetime
#

require 'spec_helper'

describe User::Trial do
  let(:user) { Factory(:user) }
  
  context "with trial user" do
    subject { Factory(:user) }
    
    it { should be_trial }
  end
  
  context "with user" do
    subject { Factory(:user, :trial_ended_at => Time.now.utc) }
    
    it { should_not be_trial }
  end
  
  describe "module method" do
    
    describe "supervise_users" do
      
      it "should send info email when user reaches 50%" do
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits / 2)
        
        lambda { User::Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(1)
        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.from.should == ["SublimeVideo <noreply@sublimevideo.net>"]
        last_delivery.to.should include user.email
        last_delivery.subject.should include "Trial usage has reached 50%"
        user.reload.trial_usage_information_email_sent_at.should be_present
      end
      
      it "should not send info email when user reaches 50% if info email already sent" do
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits / 2)
        User::Trial.supervise_users
        
        lambda { User::Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(0)
      end
      
      it "should not send info email when user is not in trial" do
        user = Factory(:user, :trial_ended_at => Time.now.utc)
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits / 2)
        
        lambda { User::Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(0)
      end
      
      it "should not send info email when user has entered credit card info" do
        user = Factory(:user, :cc_type => "Visa", :cc_last_digits => "1234")
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits / 2)
        
        lambda { User::Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(0)
      end
      
      it "should send warning email when user reach 90%" do
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits / 1.1)
        
        lambda { User::Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(1)
        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.to.should include user.email
        last_delivery.subject.should include "Warning! Trial usage has reached 90%"
        
        user.reload.trial_usage_warning_email_sent_at.should be_present
      end
      
      it "should set trial_end_at, suspend account and sent email if user has no credit car when trial is over" do
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits)
        
        lambda { User::Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(1)
        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.to.should include user.email
        last_delivery.subject.should include "Your account has been suspended"
        last_delivery.body.to_s.should include "Trial is over!"
        
        user.reload.trial_ended_at.should be_present
        user.should be_suspended
      end
      
      it "should just set trial_end_at when trial is over and user has entered credit car inot" do
        user = Factory(:user, :cc_type => "Visa", :cc_last_digits => "1234")
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits)
        lambda { User::Trial.supervise_users }.should change(ActionMailer::Base.deliveries, :size).by(0)
        
        user.reload.trial_ended_at.should be_present
      end
      
      it "should launch delayed supervise_users" do
        lambda { User::Trial.supervise_users }.should change(Delayed::Job, :count).by(1)
      end
      
      it "should not launch delayed supervise_users if one pending already present" do
        User::Trial.supervise_users
        lambda { User::Trial.supervise_users }.should change(Delayed::Job, :count).by(0)
      end
      
    end
    
  end
  
  describe "user instance methods extension" do
    
    describe "trial_usage_percentage" do
      
      it "should be calculated only from current_invoice if user has no invoice" do
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits / 3)
        user.trial_usage_percentage.should == 33
      end
      
      pending "should be calculated from past invoice + current_invoice" do
        invoice = create_invoice(:loader_hits => User::Trial.free_loader_hits / 4, :calculate => true)
        Factory(:site, :user => invoice.user, :loader_hits_cache => User::Trial.free_loader_hits / 4)
        invoice.user.trial_usage_percentage.should == 50
      end
      
      it "should take the most used between loader_hits & player_hits" do
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits / 5, :player_hits_cache => User::Trial.free_player_hits / 4)
        user.trial_usage_percentage.should == 25
      end
      
      it "should take the less used between loader_hits & player_hits if false is given (return the non active percentage)" do
        Factory(:site, :user => user, :loader_hits_cache => User::Trial.free_loader_hits / 5, :player_hits_cache => User::Trial.free_player_hits / 4)
        user.trial_usage_percentage(false).should == 20
      end
      
      it "should be greather than 100 when over" do
        Factory(:site, :user => user, :player_hits_cache => User::Trial.free_player_hits * 2)
        user.trial_usage_percentage.should > 100
      end
      
    end
    
  end
  
end
