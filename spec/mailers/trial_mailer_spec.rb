require 'spec_helper'

describe TrialMailer do
  subject { Factory(:user) }
  
  describe "common checks" do
    %w[usage_information usage_warning].each do |mail|
      before(:each) do
        subject
        ActionMailer::Base.deliveries.clear
        TrialMailer.send(mail, subject).deliver
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
  
  describe "#usage_information" do
    before(:each) do
      TrialMailer.usage_information(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    it "should set proper subject" do
      @last_delivery.subject.should == "Trial usage has reached 50%"
    end
    
    it "should set a body that contain infos" do
      @last_delivery.body.raw_source.should include "You trial limit has reached 50%"
    end
  end
  
  describe "#usage_warning" do
    before(:each) do
      TrialMailer.usage_warning(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    it "should set proper subject" do
      @last_delivery.subject.should == "Warning! Trial usage has reached 90%"
    end
    
    it "should set a body that contain infos" do
      @last_delivery.body.raw_source.should include "Warning!!! You trial limit has reached 90%"
    end
  end
  
end