require 'spec_helper'

describe MailMailer do
  subject { Factory(:user) }
  
  before(:each) do
    @template = Factory(:mail_template)
    subject
    ActionMailer::Base.deliveries.clear
  end
  
  describe "common checks" do
    %w[send_mail_with_template].each do |mail|
      before(:each) do
        MailMailer.send(mail, subject, @template).deliver
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
  
  describe "#send_mail_with_template" do
    before(:each) do
      MailMailer.send_mail_with_template(subject, @template).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end
    
    it "should set subject to Liquidified template.subject" do
      @last_delivery.subject.should == Liquid::Template.parse(@template.subject).render("user" => subject)
      @last_delivery.subject.should == "John Doe (#{subject.email}), help us shaping the right pricing"
    end
    
    it "should set the body to Liquidified-simple_formated-auto_linked template.body" do
      @last_delivery.body.encoded.should == Liquid::Template.parse(@template.body).render("user" => subject)
      @last_delivery.body.encoded.should == "Hi John Doe (#{subject.email}), please respond to the survey, by clicking on the following link:\r\nhttp://survey.com"
    end
  end
  
end