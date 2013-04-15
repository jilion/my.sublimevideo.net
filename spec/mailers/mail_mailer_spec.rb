require 'spec_helper'

describe MailMailer do

  it_should_behave_like "common mailer checks", %w[send_mail_with_template], params: -> { [FactoryGirl.create(:user).id, FactoryGirl.create(:mail_template).id] }

  before do
    @template = create(:mail_template)
    subject # send confirmation mail
    ActionMailer::Base.deliveries.clear
  end
  subject { create(:user) }

  describe "#send_mail_with_template" do
    before do
      described_class.send_mail_with_template(subject.id, @template.id).deliver
    end

    it "should set subject to Liquidified template.subject" do
      last_delivery.subject.should eq Liquid::Template.parse(@template.subject).render(user: subject)
    end

    it "should set the body to Liquidified-simple_formated-auto_linked template.body" do
      last_delivery.body.encoded.gsub(/\r\n/, ' ').should include Liquid::Template.parse(@template.body).render(user: subject)
    end
  end

end
