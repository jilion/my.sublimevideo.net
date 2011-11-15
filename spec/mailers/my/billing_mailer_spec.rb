require 'spec_helper'

describe My::BillingMailer do

  it_should_behave_like "common mailer checks", %w[trial_will_end], from: ["billing@sublimevideo.net"], params: Factory.create(:site)
  it_should_behave_like "common mailer checks", %w[credit_card_will_expire], from: ["billing@sublimevideo.net"], params: Factory.create(:user, cc_expire_on: 1.day.from_now)
  it_should_behave_like "common mailer checks", %w[transaction_succeeded transaction_failed], from: ["billing@sublimevideo.net"], params: Factory.create(:transaction, invoices: [Factory.create(:invoice)])
  it_should_behave_like "common mailer checks", %w[too_many_charging_attempts], from: ["billing@sublimevideo.net"], params: lambda { Factory.create(:invoice) }

  describe "specific checks" do
    before(:all) do
      @user        = Factory.create(:user, cc_expire_on: 1.day.from_now)
      @site        = Factory.create(:site, user: @user, trial_started_at: 8.days.ago)
      @invoice     = Factory.create(:invoice)
      @transaction = Factory.create(:transaction, invoices: [@invoice])
    end

    describe "#trial_will_end" do
      context "site has no hostname" do
        before(:all) do
          @site.hostname = nil
          described_class.trial_will_end(@site).deliver
          @last_delivery = ActionMailer::Base.deliveries.last
        end

        it { @last_delivery.subject.should eq I18n.t("mailer.billing_mailer.trial_will_end", hostname: 'your site', days: BusinessModel.days_for_trial-8) }
      end

      context "site has a hostname" do
        before(:all) do
          @site.reload
          described_class.trial_will_end(@site).deliver
          @last_delivery = ActionMailer::Base.deliveries.last
        end

        it { @last_delivery.subject.should eq   I18n.t("mailer.billing_mailer.trial_will_end", hostname: @site.hostname, days: BusinessModel.days_for_trial-8) }
        it { @last_delivery.body.encoded.should include "Dear #{@user.name}," }
        it { @last_delivery.body.encoded.should include I18n.l(@site.trial_end, format: :named_date) }
        it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/sites/#{@site.to_param}/plan/edit" }
        it { @last_delivery.body.encoded.should include "http://docs.#{ActionMailer::Base.default_url_options[:host]}" }
      end
    end

    describe "#credit_card_will_expire" do
      before(:all) do
        described_class.credit_card_will_expire(@user).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq  I18n.t("mailer.billing_mailer.credit_card_will_expire") }
      it { @last_delivery.body.encoded.should include "Dear #{@user.name}," }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/account/billing/edit" }
      it { @last_delivery.body.encoded.should include "If you have any questions, please <a href=\"mailto:#{h I18n.t("mailer.from_billing")}\">email us</a>." }
    end

    describe "#transaction_succeeded" do
      before(:all) do
        described_class.transaction_succeeded(@transaction).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq   I18n.t("mailer.billing_mailer.transaction_succeeded") }
      it { @last_delivery.body.encoded.should include @transaction.user.name }
      it { @last_delivery.body.encoded.should include "Your latest SublimeVideo payment has been approved." }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/invoices/#{@invoice.to_param}" }
      it { @last_delivery.body.encoded.should include "If you have any questions, please <a href=\"mailto:#{h I18n.t("mailer.from_billing")}\">email us</a>." }
    end

    describe "#transaction_failed" do
      before(:all) do
        described_class.transaction_failed(@transaction).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq   I18n.t("mailer.billing_mailer.transaction_failed") }
      it { @last_delivery.body.encoded.should include @transaction.user.name }
      it { @last_delivery.body.encoded.should include "Your credit card could not be charged." }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/sites" }
      it { @last_delivery.body.encoded.should include "If you have any questions, please <a href=\"mailto:#{h I18n.t("mailer.from_billing")}\">email us</a>." }
    end

    describe "#too_many_charging_attempts" do
      before(:all) do
        described_class.too_many_charging_attempts(@invoice).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq   I18n.t("mailer.billing_mailer.too_many_charging_attempts", hostname: @invoice.site.hostname) }
      it { @last_delivery.body.encoded.should include "The payment for #{@invoice.site.hostname} has failed multiple times, no further charging attempt will be made." }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/sites/#{@invoice.site.to_param}/plan/edit" }
      it { @last_delivery.body.encoded.should include "Note that if the payment failed due to a problem with your credit card" }
      it { @last_delivery.body.encoded.should include "you should probably update your credit card information via the following link:" }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/account/billing/edit" }
      it { @last_delivery.body.encoded.should include "If you have any questions, please <a href=\"mailto:#{h I18n.t("mailer.from_billing")}\">email us</a>." }
    end
  end

end
