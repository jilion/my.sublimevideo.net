require 'spec_helper'

describe BillingMailer do
  before(:all) do
    @user        = Factory.create(:user, cc_expire_on: 1.day.from_now)
    @site        = Factory.create(:site, user: @user, trial_started_at: 8.days.ago)
    @invoice     = Factory.create(:invoice)
    @transaction = Factory.create(:transaction, invoices: [@invoice])
  end

  it_should_behave_like "common mailer checks", %w[too_many_charging_attempts], from: ["billing@sublimevideo.net"], params: Factory.create(:invoice, site: Factory.create(:site))
  it_should_behave_like "common mailer checks", %w[trial_will_end], from: ["billing@sublimevideo.net"], params: Factory.create(:site)
  it_should_behave_like "common mailer checks", %w[credit_card_will_expire], from: ["billing@sublimevideo.net"], params: Factory.create(:user, cc_expire_on: 1.day.from_now)
  it_should_behave_like "common mailer checks", %w[transaction_succeeded transaction_failed], from: ["billing@sublimevideo.net"], params: Factory.create(:transaction, invoices: [Factory.create(:invoice)])

  describe "#trial_will_end" do
    before(:each) do
      described_class.trial_will_end(@site).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should eql "Your trial for #{@site.hostname.presence || 'your site'} will expire in #{BusinessModel.days_for_trial-8} days"
      @last_delivery.body.encoded.should include "Dear #{@user.full_name},"
      @last_delivery.body.encoded.should include "#{BusinessModel.days_for_trial-8} days"
      @last_delivery.body.encoded.should include I18n.l(@site.trial_end, format: :named_date)
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/sites/#{@site.token}/plan/edit"
      @last_delivery.body.encoded.should include "http://docs.sublimevideo.net"
    end
  end

  describe "#credit_card_will_expire" do
    before(:each) do
      described_class.credit_card_will_expire(@user).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should eql "Your credit card will expire at the end of the month"
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
      @last_delivery.subject.should eql "Payment approved"
      @last_delivery.body.encoded.should include @transaction.user.full_name
      @last_delivery.body.encoded.should include "Your latest SublimeVideo payment has been approved."
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/invoices/#{@invoice.to_param}"
      @last_delivery.body.encoded.should include 'If you have any questions, please <a href="mailto:billing@sublimevideo.net">email us</a>.'
    end
  end

  describe "#transaction_failed" do
    before(:all) do
      described_class.transaction_failed(@transaction).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should eql "Problem processing your payment"
      @last_delivery.body.encoded.should include @transaction.user.full_name
      @last_delivery.body.encoded.should include "Your credit card could not be charged."
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/sites"
      @last_delivery.body.encoded.should include 'If you have any questions, please <a href="mailto:billing@sublimevideo.net">email us</a>.'
    end
  end

  describe "#too_many_charging_attempts" do
    before(:all) do
      described_class.too_many_charging_attempts(@invoice).deliver
      @last_delivery = ActionMailer::Base.deliveries.last
    end

    specify do
      @last_delivery.subject.should eql "Payment for #{@invoice.site.hostname} has failed multiple times"
      @last_delivery.body.encoded.should include "The payment for #{@invoice.site.hostname} has failed multiple times, no further charging attempt will be made."
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/sites/#{@invoice.site.to_param}/plan/edit"
      @last_delivery.body.encoded.should include "Note that if the payment failed due to a problem with your credit card"
      @last_delivery.body.encoded.should include "you should probably update your credit card information via the following link:"
      @last_delivery.body.encoded.should include "https://#{ActionMailer::Base.default_url_options[:host]}/card/edit"
    end
  end

end
