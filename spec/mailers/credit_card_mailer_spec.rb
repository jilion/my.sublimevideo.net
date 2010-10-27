require 'spec_helper'

describe CreditCardMailer do
  subject { Factory(:user, :cc_expire_on => 1.day.from_now) }
  
  describe "common checks" do
    %w[is_expired will_expire].each do |mail|
      before(:each) do
        subject
        ActionMailer::Base.deliveries.clear
        CreditCardMailer.send(mail, subject).deliver
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
  
  describe "#is_expired" do
    before(:each) do
      CreditCardMailer.is_expired(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    it "should set subject" do
      @last_delivery.subject.should == "Your credit card is expired"
    end
    
    it "should set a body that contain the link to edit the credit card" do
      @last_delivery.body.raw_source.should include "https://#{ActionMailer::Base.default_url_options[:host]}/card/edit"
    end
  end
  
  describe "#will_expire" do
    before(:each) do
      CreditCardMailer.will_expire(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    it "should set proper subject" do
      @last_delivery.subject.should == "Your credit card will expire at the end of the month"
    end
    
    it "should set a body that contains the link to edit the credit card" do
      @last_delivery.body.raw_source.should include "https://#{ActionMailer::Base.default_url_options[:host]}/card/edit"
    end
  end
  
end