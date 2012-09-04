require 'spec_helper'

describe BillingMailer do

  it_should_behave_like "common mailer checks", %w[trial_has_started], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:site, plan_id: FactoryGirl.create(:trial_plan).id).id }
  it_should_behave_like "common mailer checks", %w[trial_will_expire], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:site, plan_id: FactoryGirl.create(:trial_plan).id).id }
  it_should_behave_like "common mailer checks", %w[trial_has_expired], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:site, plan_id: FactoryGirl.create(:trial_plan).id).id }
  it_should_behave_like "common mailer checks", %w[credit_card_will_expire], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:user, cc_expire_on: 1.day.from_now).id }
  it_should_behave_like "common mailer checks", %w[transaction_succeeded transaction_failed], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:transaction, invoices: [FactoryGirl.create(:invoice)]).id }
  it_should_behave_like "common mailer checks", %w[too_many_charging_attempts], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:invoice) }

  describe "specific checks" do
    let(:user)        { create(:user, cc_expire_on: 1.day.from_now) }
    let(:site)        { create(:site, plan_id: create(:trial_plan).id, user: user, trial_started_at: 8.days.ago) }
    let(:invoice)     { create(:invoice) }
    let(:transaction) { create(:transaction, invoices: [invoice]) }

    describe "#trial_has_started" do
      context "user has a cc" do
        before do
          described_class.trial_has_started(site.id).deliver
        end

        it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_has_started_hostname', hostname: site.hostname) }
        it { last_delivery.body.encoded.should include "Dear #{user.name}," }
        it { last_delivery.body.encoded.should include I18n.l(site.trial_end.tomorrow, format: :named_date) }
        it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/sites/#{site.to_param}/plan/edit" }
      end

      context "user has no cc" do
        before do
          user.reset_credit_card_info
          described_class.trial_has_started(site.id).deliver
          last_delivery = ActionMailer::Base.deliveries.last
        end

        it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_has_started_hostname', hostname: site.hostname) }
        it { last_delivery.body.encoded.should include "Dear #{user.name}," }
        it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/account/billing/edit" }
      end
    end

    describe "#trial_will_expire" do
      context 'user has a credit card' do
        before do
          site.update_attribute(:plan_started_at, (BusinessModel.days_for_trial-1).days.ago)
          described_class.trial_will_expire(site.id).deliver
          last_delivery = ActionMailer::Base.deliveries.last
          Capybara.app_host = "http://my.sublimevideo.dev"
        end

        it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_will_expire.today', hostname: site.hostname, days: 1) }
        it { last_delivery.body.encoded.should include "Dear #{user.name}," }
        it { last_delivery.body.encoded.should include I18n.l(site.trial_end.tomorrow, format: :named_date) }
        it { last_delivery.body.encoded.should_not include "https://my.sublimevideo.dev/account/billing/edit" }
      end

      context 'user has no credit card' do
        let(:user) { create(:user_no_cc) }
        before do
          site.update_attribute(:plan_started_at, (BusinessModel.days_for_trial-1).days.ago)
          described_class.trial_will_expire(site.reload.id).deliver
          last_delivery = ActionMailer::Base.deliveries.last
          Capybara.app_host = "http://my.sublimevideo.dev"
        end

        it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_will_expire.today', hostname: site.hostname, days: 1) }
        it { last_delivery.body.encoded.should include "Dear #{user.name}," }
        it { last_delivery.body.encoded.should include I18n.l(site.trial_end.tomorrow, format: :named_date) }
        it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/account/billing/edit" }
      end
    end

    describe "#trial_has_expired" do
      before do
        site.update_attribute(:plan_started_at, BusinessModel.days_for_trial.days.ago)
        described_class.trial_has_expired(site.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_has_expired', hostname: site.hostname, count: 1) }
      it { last_delivery.body.encoded.should include "Dear #{user.name}," }
      it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/sites/#{site.to_param}/plan/edit" }
    end

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

    describe "#too_many_charging_attempts" do
      before do
        described_class.too_many_charging_attempts(invoice.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.too_many_charging_attempts', hostname: invoice.site.hostname) }
      it { last_delivery.body.encoded.should include "The payment for" }
      it { last_delivery.body.encoded.should include "has failed multiple times" }
      it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/sites/#{invoice.site.to_param}/plan/edit" }
      it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/account/billing/edit" }
      it { last_delivery.body.encoded.should include I18n.t("mailer.reply_to_this_email") }
    end
  end

end
