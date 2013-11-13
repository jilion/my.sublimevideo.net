require 'spec_helper'

describe BillingMailer do

  it_behaves_like "common mailer checks", %w[credit_card_will_expire], from: [I18n.t('mailer.billing.email')], params: -> { FactoryGirl.create(:user, cc_expire_on: 1.day.from_now).id }
  it_behaves_like "common mailer checks", %w[transaction_succeeded transaction_failed], from: [I18n.t('mailer.billing.email')], params: -> { FactoryGirl.create(:transaction, invoices: [FactoryGirl.create(:invoice)]).id }
  # it_behaves_like "common mailer checks", %w[trial_will_expire trial_has_expired], from: [I18n.t('mailer.billing.email')], params: -> { FactoryGirl.create(:addon_plan_billable_item).id }

  describe "specific checks" do
    let(:user)          { create(:user, cc_expire_on: 1.day.from_now) }
    let(:site)          { create(:site, user: user) }
    let(:invoice)       { create(:invoice, site: site) }
    let(:transaction)   { create(:transaction, invoices: [invoice]) }
    let(:billable_item) { create(:addon_plan_billable_item, site: site, state: 'trial') }

    describe "#trial_will_expire" do
      context 'user has a credit card' do
        before do
          create(:billable_item_activity, state: 'trial', item: billable_item.item, site: site, created_at: BusinessModel.days_for_trial.days.ago)
          described_class.trial_will_expire(billable_item.id).deliver
          last_delivery = ActionMailer::Base.deliveries.last
          Capybara.app_host = "http://my.sublimevideo.dev"
        end

        it 'uses the normal user name/email even if billing email is present' do
          expect(last_delivery.to).to eq [user.email]
          expect(last_delivery.body.encoded).to include "Dear #{user.name},"
        end
        it { expect(last_delivery.subject).to               eq I18n.t('mailer.billing_mailer.trial_will_expire.today', addon: "#{billable_item.item.title} add-on", days: 1) }
        it { expect(last_delivery.body.encoded).to     include "#{BusinessModel.days_for_trial}-day" }
        it { expect(last_delivery.body.encoded).to     include I18n.l(TrialHandler.new(site).trial_end_date(billable_item.item).tomorrow, format: :named_date) }
        it { expect(last_delivery.body.encoded).not_to include "https://my.sublimevideo.dev/account/billing/edit" }
      end

      context 'user has no credit card' do
        let(:user) { create(:user_no_cc, billing_email: nil) }
        before do
          create(:billable_item_activity, state: 'trial', item: billable_item.item, site: site, created_at: BusinessModel.days_for_trial.days.ago)
          described_class.trial_will_expire(billable_item.id).deliver
          last_delivery = ActionMailer::Base.deliveries.last
          Capybara.app_host = "http://my.sublimevideo.dev"
        end

        it 'uses the normal user name/email even if billing email is present' do
          expect(last_delivery.to).to eq [user.email]
          expect(last_delivery.body.encoded).to include "Dear #{user.name},"
        end
        it { expect(last_delivery.subject).to           eq I18n.t('mailer.billing_mailer.trial_will_expire.today', addon: "#{billable_item.item.title} add-on", days: 1) }
        it { expect(last_delivery.body.encoded).to include "#{BusinessModel.days_for_trial}-day" }
        it { expect(last_delivery.body.encoded).to include I18n.l(TrialHandler.new(site).trial_end_date(billable_item.item).tomorrow, format: :named_date) }
        it { expect(last_delivery.body.encoded).to include "https://my.sublimevideo.dev/account/billing/edit" }
      end
    end

    describe "#trial_has_expired" do
      before do
        create(:billable_item_activity, state: 'trial', item: billable_item.item, site: site, created_at: BusinessModel.days_for_trial.days.ago)
        described_class.trial_has_expired(site, billable_item.item.class.to_s, billable_item.item.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it 'uses the normal user name/email even if billing email is present' do
        expect(last_delivery.to).to eq [user.email]
        expect(last_delivery.body.encoded).to include "Dear #{user.name},"
      end
      it { expect(last_delivery.subject).to           eq I18n.t('mailer.billing_mailer.trial_has_expired', addon: "#{billable_item.item.title} add-on", count: 1) }
      it { expect(last_delivery.body.encoded).to include "Dear #{user.name}," }
      it { expect(last_delivery.body.encoded).to include "#{BusinessModel.days_for_trial}-day" }
      it { expect(last_delivery.body.encoded).to include "https://my.sublimevideo.dev/sites/#{site.to_param}/addons" }
    end

    describe "#credit_card_will_expire" do
      let(:user) { create(:user, cc_expire_on: 1.day.from_now) }
      before do
        described_class.credit_card_will_expire(user.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it 'uses to the billing name & email if billing email is present' do
        expect(last_delivery.to).to eq [user.billing_email]
        expect(last_delivery.body.encoded).to include "Dear #{user.billing_name},"
      end
      it { expect(last_delivery.subject).to eq  I18n.t('mailer.billing_mailer.credit_card_will_expire') }
      it { expect(last_delivery.body.encoded).to include "https://my.sublimevideo.dev/account/billing/edit" }
      it { expect(last_delivery.body.encoded).to include I18n.t("mailer.reply_to_this_email") }
    end

    describe "#transaction_succeeded" do
      let(:user) { create(:user, billing_email: nil) }
      before do
        described_class.transaction_succeeded(transaction.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it 'fallbacks to the normal user name/email if no billing email is present' do
        expect(last_delivery.to).to eq [transaction.user.email]
        expect(last_delivery.body.encoded).to include "Dear #{transaction.user.name},"
      end
      it { expect(last_delivery.subject).to eq   I18n.t('mailer.billing_mailer.transaction_succeeded') }
      it { expect(last_delivery.body.encoded).to include "Your latest SublimeVideo payment has been approved." }
      it { expect(last_delivery.body.encoded).to include "https://my.sublimevideo.dev/invoices/#{invoice.to_param}" }
      it { expect(last_delivery.body.encoded).to include I18n.t("mailer.reply_to_this_email") }
    end

    describe "#transaction_failed" do
      let(:user) { create(:user, billing_name: nil) }
      before do
        described_class.transaction_failed(transaction.id).deliver
        last_delivery = ActionMailer::Base.deliveries.last
      end

      it 'uses to the billing name & email if billing email is present' do
        expect(last_delivery.to).to eq [transaction.user.billing_email]
        expect(last_delivery.body.encoded).to include "Dear #{transaction.user.billing_email},"
      end
      it { expect(last_delivery.subject).to eq   I18n.t('mailer.billing_mailer.transaction_failed') }
      it { expect(last_delivery.body.encoded).to include "There has been a problem processing your payment and your credit card could not be charged." }
      it { expect(last_delivery.body.encoded).to include "https://my.sublimevideo.dev/sites" }
      it { expect(last_delivery.body.encoded).to include I18n.t("mailer.reply_to_this_email") }
    end
  end

end
