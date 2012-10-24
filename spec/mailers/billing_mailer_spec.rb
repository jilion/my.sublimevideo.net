require 'spec_helper'

describe BillingMailer do

  it_should_behave_like "common mailer checks", %w[credit_card_will_expire], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:user, cc_expire_on: 1.day.from_now).id }
  it_should_behave_like "common mailer checks", %w[transaction_succeeded transaction_failed], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:transaction, invoices: [FactoryGirl.create(:invoice)]).id }
  # it_should_behave_like "common mailer checks", %w[trial_will_expire trial_has_expired], from: [I18n.t('mailer.billing.email')], params: lambda { FactoryGirl.create(:addon_plan_billable_item).id }

  describe "specific checks" do
    let(:user)          { create(:user, cc_expire_on: 1.day.from_now) }
    let(:site)          { create(:site, user: user, trial_started_at: 8.days.ago) }
    let(:invoice)       { create(:invoice) }
    let(:transaction)   { create(:transaction, invoices: [invoice]) }
    let(:billable_item) { create(:addon_plan_billable_item, site: site, state: 'trial') }

    describe "#trial_will_expire" do
      before do
        create(:billable_item_activity, state: 'trial', item: billable_item.item, site: site, created_at: BusinessModel.days_for_trial.days.ago)
      end

      context 'user has a credit card' do
        before do
          described_class.trial_will_expire(billable_item.id).deliver
          last_delivery = ActionMailer::Base.deliveries.last
          Capybara.app_host = "http://my.sublimevideo.dev"
        end

        it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_will_expire.today', addon: billable_item.item.title, days: 1) }
        it { last_delivery.body.encoded.should include "Dear #{user.name}," }
        it { last_delivery.body.encoded.should include I18n.l(site.trial_end_date_for_billable_item(billable_item.item).tomorrow, format: :named_date) }
        it { last_delivery.body.encoded.should_not include "https://my.sublimevideo.dev/account/billing/edit" }
      end

      context 'user has no credit card' do
        let(:user) { create(:user_no_cc) }
        before do
          described_class.trial_will_expire(billable_item.id).deliver
          last_delivery = ActionMailer::Base.deliveries.last
          Capybara.app_host = "http://my.sublimevideo.dev"
        end

        it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_will_expire.today', addon: billable_item.item.title, days: 1) }
        it { last_delivery.body.encoded.should include "Dear #{user.name}," }
        it { last_delivery.body.encoded.should include I18n.l(site.trial_end_date_for_billable_item(billable_item.item).tomorrow, format: :named_date) }
        it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/account/billing/edit" }
      end
    end

    describe "#trial_has_expired" do
      before do
        described_class.trial_has_expired(site, billable_item.item.class.to_s, billable_item.item.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it { last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_has_expired', addon: billable_item.item.title, count: 1) }
      it { last_delivery.body.encoded.should include "Dear #{user.name}," }
      it { last_delivery.body.encoded.should include "https://my.sublimevideo.dev/sites/#{site.to_param}/addons" }
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
  end

end
