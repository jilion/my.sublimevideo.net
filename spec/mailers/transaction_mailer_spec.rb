require 'spec_helper'

describe TransactionMailer do
  before(:all) do
    @invoice = Factory(:invoice)
    @transaction = Factory(:transaction, invoices: [@invoice])
  end
  subject { @transaction }

  describe "charging_failed common checks" do
    before(:each) do
      ActionMailer::Base.deliveries.clear
      TransactionMailer.charging_failed(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      ActionMailer::Base.deliveries.size.should == 1
      @last_delivery.from.should == ["billing@sublimevideo.net"]
      @last_delivery.to.should == [subject.user.email]
      @last_delivery.content_type.should == "text/plain; charset=UTF-8"
    end
  end

  describe "#charging_failed" do
    before(:all) do
      TransactionMailer.charging_failed(subject).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should == "Problem processing your payment"
      @last_delivery.body.encoded.should include subject.user.full_name
      @last_delivery.body.encoded.should include "Your credit card could not be charged."
      @last_delivery.body.encoded.should include "https://localhost:3000/sites"
      @last_delivery.body.encoded.should include "https://localhost:3000/support#billing"
    end
  end

end
