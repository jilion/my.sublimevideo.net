require 'spec_helper'

describe LimitAlertMailer do
  subject { Factory(:user) }
  
  describe "common checks" do
    %w[limit_exceeded].each do |mail|
      before(:each) do
        subject
        ActionMailer::Base.deliveries.clear
        LimitAlertMailer.send(mail, subject).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end
      
      it "should send an email" do
        ActionMailer::Base.deliveries.size.should == 1
      end
      
      it "should send the mail from noreply@sublimevideo.net" do
        @last_delivery.from.should == ["noreply@sublimevideo.net"]
      end
      
      it "should send the mail to user.email" do
        @last_delivery.to.should == [subject.email]
      end
      
      it "should set content_type to text/plain (set by default by the Mail gem)" do
        @last_delivery.content_type.should == "text/plain; charset=UTF-8"
      end
    end
  end
  
  describe "#limit_exceeded" do
    before(:each) do
      LimitAlertMailer.limit_exceeded(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    it "should set proper subject" do
      @last_delivery.subject.should == "Limit exceeded"
    end
    
    it "should set a body that contain infos" do
      @last_delivery.body.raw_source.should include "$#{subject.limit_alert_amount / 100.0}"
    end
  end
  
end