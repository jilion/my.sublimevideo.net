# == Schema Information
#
# Table name: users
#
#  limit_alert_amount                    :integer         default(0)
#  limit_alert_email_sent_at             :datetime
#

require 'spec_helper'

describe User::LimitAlert do
  
  it "should have limit alert alredy sent" do
    user = Factory(:user, :limit_alert_email_sent_at => Time.now.utc)
    user.limit_alert_sent?.should be_true
  end
  
  context "user with limit alert amount exceeded" do
    before(:each) do
      @user = Factory(:user, :limit_alert_amount => 2000)
      Factory(:site, :user => @user, :loader_hits_cache => User::Trial.free_loader_hits + 2001)
    end
    
    subject { @user }
    
    it { should be_limit_alert_amount_exceeded }
    
    describe "send_limit_alerts method" do
      
      it "should send one limit exceeded email" do
        lambda { User::LimitAlert.send_limit_alerts }.should change(ActionMailer::Base.deliveries, :size).by(1)
        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.from.should == ["noreply@sublimevideo.net"]
        last_delivery.to.should include subject.email
        last_delivery.subject.should include "Limit exceeded"
        subject.reload.limit_alert_email_sent_at.should be_present
      end
      
      it "should not send info email when user reach 50% if info email already sent" do
        User::LimitAlert.send_limit_alerts
        lambda { User::LimitAlert.send_limit_alerts }.should_not change(ActionMailer::Base.deliveries, :size)
      end
      
      it "should launch delayed send_limit_alerts" do
        lambda { User::LimitAlert.send_limit_alerts }.should change(Delayed::Job, :count).by(1)
      end
      
      it "should not launch delayed send_limit_alerts if one pending already present" do
        User::LimitAlert.send_limit_alerts
        lambda { User::LimitAlert.send_limit_alerts }.should_not change(Delayed::Job, :count)
      end
      
    end
    
  end
  
  it "should clear limit_alert_email_sent_at when user increments limit_alert_amount" do
    user = Factory(:user, :limit_alert_amount => 2000, :limit_alert_email_sent_at => Time.now.utc)
    user.update_attributes(:limit_alert_amount => 10000)
    user.reload.limit_alert_email_sent_at.should be_nil
  end
  
end