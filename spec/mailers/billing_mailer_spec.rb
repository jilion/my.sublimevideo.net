require 'spec_helper'

describe BillingMailer do
  before(:all) do
    @user        = Factory(:user, :cc_expire_on => 1.day.from_now)
    @invoice     = Factory(:invoice)
    @transaction = Factory(:transaction, invoices: [@invoice])
  end

  it_should_behave_like "common mailer checks", %w[credit_card_will_expire], :from => ["billing@sublimevideo.net"], :params => [Factory(:user, :cc_expire_on => 1.day.from_now)]
  it_should_behave_like "common mailer checks", %w[transaction_succeeded transaction_failed], :from => ["billing@sublimevideo.net"], :params => [Factory(:transaction, invoices: [Factory(:invoice)])]

  describe "#credit_card_will_expire" do
    before(:each) do
      described_class.credit_card_will_expire(@user).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should == "Your credit card will expire at the end of the month"
      @last_delivery.body.encoded.should include "Dear #{@user.full_name},"
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/card/edit"
    end
  end

  describe "#transaction_succeeded" do
    before(:all) do
      described_class.transaction_succeeded(@transaction).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should == "Payment approved"
      @last_delivery.body.encoded.should include @transaction.user.full_name
      @last_delivery.body.encoded.should include "Your latest SublimeVideo payment has been approved."
      @last_delivery.body.encoded.should include "https://localhost:3000/invoices/#{@invoice.to_param}"
      @last_delivery.body.encoded.should include "https://localhost:3000/support#billing"
    end
  end

  describe "#transaction_failed" do
    before(:all) do
      described_class.transaction_failed(@transaction).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should == "Problem processing your payment"
      @last_delivery.body.encoded.should include @transaction.user.full_name
      @last_delivery.body.encoded.should include "Your credit card could not be charged."
      @last_delivery.body.encoded.should include "https://localhost:3000/sites"
      @last_delivery.body.encoded.should include "https://localhost:3000/support#billing"
    end
  end

end
