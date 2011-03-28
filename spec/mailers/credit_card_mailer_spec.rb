require 'spec_helper'

describe CreditCardMailer do
  before(:all) do
    @user = Factory(:user, :cc_expire_on => 1.day.from_now)
  end
  subject { @user }

  it_should_behave_like "common mailer checks", %w[will_expire], :params => [Factory(:user, :cc_expire_on => 1.day.from_now)]

  describe "#will_expire" do
    before(:each) do
      CreditCardMailer.will_expire(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    it "should set proper subject" do
      @last_delivery.subject.should == "Your credit card will expire at the end of the month"
    end

    it "should set a body that contains the link to edit the credit card" do
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/card/edit"
    end

    it "should set a body that contains the link to edit the credit card" do
      @last_delivery.body.encoded.should include "Dear #{@user.full_name},"
    end
  end

end
