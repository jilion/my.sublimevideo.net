require 'spec_helper'

describe BillingMailer do

  it_should_behave_like "common mailer checks", %w[credit_card_will_expire], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:user, cc_expire_on: 1.day.from_now).id }
  it_should_behave_like "common mailer checks", %w[transaction_succeeded transaction_failed], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:transaction, invoices: [FactoryGirl.create(:invoice)]).id }

  describe "specific checks" do
    let(:user)        { create(:user, cc_expire_on: 1.day.from_now) }
    let(:site)        { create(:site, user: user, trial_started_at: 8.days.ago) }
    let(:invoice)     { create(:invoice) }
    let(:transaction) { create(:transaction, invoices: [invoice]) }

    describe "#credit_card_will_expire" do
      before do
        described_class.credit_card_will_expire(user.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it { last_delivery.subject.should eq  I18n.t('mailer.billing_mailer.credit_card_will_expire') }
      it { last_delivery.body.encoded.should include "Dear #{user.name}," }
      it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/account/billing/edit" }
      it { last_delivery.body.encoded.should include I18n.t("mailer.reply_to_this_email") }
    end

    describe "#transaction_succeeded" do
      before do
        described_class.transaction_succeeded(transaction.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.transaction_succeeded') }
      it { last_delivery.body.encoded.should include transaction.user.name }
      it { last_delivery.body.encoded.should include "Your latest SublimeVideo payment has been approved." }
      it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/invoices/#{invoice.to_param}" }
      it { last_delivery.body.encoded.should include I18n.t("mailer.reply_to_this_email") }
    end

    describe "#transaction_failed" do
      before do
        described_class.transaction_failed(transaction.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.transaction_failed') }
      it { last_delivery.body.encoded.should include transaction.user.name }
      it { last_delivery.body.encoded.should include "There has been a problem processing your payment and your credit card could not be charged." }
      it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/sites" }
      it { last_delivery.body.encoded.should include I18n.t("mailer.reply_to_this_email") }
    end
  end

end
