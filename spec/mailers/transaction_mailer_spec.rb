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
      @last_delivery.from.should == ["noreply@sublimevideo.net"]
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
      @last_delivery.subject.should == "Charging for \"SublimeVideo Invoices: ##{@invoice.reference}\" has failed."
      @last_delivery.body.encoded.should include subject.user.full_name
      @last_delivery.body.encoded.should include "We couldn't charge the following invoices: ##{@invoice.reference}"
      @last_delivery.body.encoded.should include "Transaction information:"
      @last_delivery.body.encoded.should include "https://my.sublimevideo.net/support"
    end
  end

end
