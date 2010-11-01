require 'spec_helper'

describe UserMailer do
  subject { Factory(:user) }
  
  describe "common checks" do
    %w[account_suspended].each do |mail|
      before(:each) do
        subject
        ActionMailer::Base.deliveries.clear
        UserMailer.send(mail, subject, :invoice_problem).deliver
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
  
  describe "#account_suspended" do
    context "when reason given is :invoice_problem" do
      before(:each) do
        UserMailer.account_suspended(subject, :invoice_problem).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end
      
      it "should set proper subject" do
        @last_delivery.subject.should == "Your account has been suspended"
      end
      
      it "should set a body that contain infos" do
        @last_delivery.body.raw_source.should include "Hi"
      end
    end
  end
  
end