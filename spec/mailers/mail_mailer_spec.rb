require 'spec_helper'

describe MailMailer do
  subject { Factory(:user) }

  before(:each) do
    @template = Factory(:mail_template)
    subject # send confirmation mail
    ActionMailer::Base.deliveries.clear
  end

  it_should_behave_like "common mailer checks", %w[send_mail_with_template], :params => [Factory(:user), Factory(:mail_template)], :content_type => %r{text/html; charset=UTF-8}

  describe "#send_mail_with_template" do
    before(:each) do
      MailMailer.send_mail_with_template(subject, @template).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set subject to Liquidified template.subject" do
      @last_delivery.subject.should == Liquid::Template.parse(@template.subject).render("user" => subject)
      @last_delivery.subject.should include "John Doe (#{subject.email}), help us shaping the right pricing"
    end

    it "should set the body to Liquidified-simple_formated-auto_linked template.body" do
      @last_delivery.body.encoded.should == Liquid::Template.parse(@template.body).render("user" => subject)
      @last_delivery.body.encoded.should include "Hi John Doe (#{subject.email}), please respond to the survey, by clicking on the following url: http://survey.com"
    end
  end

end