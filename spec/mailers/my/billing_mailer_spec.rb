require 'spec_helper'

describe My::BillingMailer do

  it_should_behave_like "common mailer checks", %w[trial_has_started], from: [I18n.t('mailer.billing.email')], params: Factory.create(:site), content_type: %r{text/html; charset=UTF-8}
  it_should_behave_like "common mailer checks", %w[trial_will_expire], from: [I18n.t('mailer.billing.email')], params: Factory.create(:site), content_type: %r{text/html; charset=UTF-8}
  it_should_behave_like "common mailer checks", %w[trial_has_expired], from: [I18n.t('mailer.billing.email')], params: [Factory.create(:site), Factory.create(:plan)], content_type: %r{text/html; charset=UTF-8}
  it_should_behave_like "common mailer checks", %w[credit_card_will_expire], from: [I18n.t('mailer.billing.email')], params: Factory.create(:user, cc_expire_on: 1.day.from_now)
  it_should_behave_like "common mailer checks", %w[transaction_succeeded transaction_failed], from: [I18n.t('mailer.billing.email')], params: Factory.create(:transaction, invoices: [Factory.create(:invoice)])
  it_should_behave_like "common mailer checks", %w[too_many_charging_attempts], from: [I18n.t('mailer.billing.email')], params: lambda { Factory.create(:invoice) }

  describe "specific checks" do
    before(:all) do
      @user        = Factory.create(:user, cc_expire_on: 1.day.from_now)
      @site        = Factory.create(:site, user: @user, trial_started_at: 8.days.ago)
      @invoice     = Factory.create(:invoice)
      @transaction = Factory.create(:transaction, invoices: [@invoice])
    end

    describe "#trial_has_started" do
      context "user has a cc" do
        before(:all) do
          described_class.trial_has_started(@site.reload).deliver
          @last_delivery = ActionMailer::Base.deliveries.last
        end

        it { @last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_has_started', hostname: @site.hostname) }
        it { @last_delivery.body.encoded.should include "Dear #{@user.name}," }
        it { @last_delivery.body.encoded.should include I18n.l(@site.trial_end.tomorrow, format: :named_date) }
        it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/sites/#{@site.to_param}/plan/edit" }
      end
      
      context "user has no cc" do
        before(:all) do
          @user.reset_credit_card_info
          described_class.trial_has_started(@site.reload).deliver
          @last_delivery = ActionMailer::Base.deliveries.last
        end

        it { @last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_has_started', hostname: @site.hostname) }
        it { @last_delivery.body.encoded.should include "Dear #{@user.name}," }
        it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/account/billing/edit" }
      end
    end

    describe "#trial_will_expire" do
      before(:all) do
        @site.reload
        @site.update_attribute(:trial_started_at, (BusinessModel.days_for_trial-1).days.ago)
        described_class.trial_will_expire(@site).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_will_expire.today', hostname: @site.hostname, days: 1) }
      it { @last_delivery.body.encoded.should include "Dear #{@user.name}," }
      it { @last_delivery.body.encoded.should include I18n.l(@site.trial_end, format: :named_date) }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/account/billing/edit" }
      it { @last_delivery.body.encoded.should include "https://www.#{ActionMailer::Base.default_url_options[:host]}/help" }
    end

    describe "#trial_has_expired" do
      before(:all) do
        @site.reload
        @site.update_attribute(:trial_started_at, BusinessModel.days_for_trial.days.ago)
        described_class.trial_has_expired(@site, Factory.create(:plan)).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.trial_has_expired', hostname: @site.hostname, count: 1) }
      it { @last_delivery.body.encoded.should include "Dear #{@user.name}," }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/sites/#{@site.to_param}/plan/edit" }
    end

    describe "#credit_card_will_expire" do
      before(:all) do
        described_class.credit_card_will_expire(@user).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq  I18n.t('mailer.billing_mailer.credit_card_will_expire') }
      it { @last_delivery.body.encoded.should include "Dear #{@user.name}," }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/account/billing/edit" }
      it { @last_delivery.body.encoded.should include "If you have any questions, please email #{h I18n.t("mailer.billing.email")}." }
    end

    describe "#transaction_succeeded" do
      before(:all) do
        described_class.transaction_succeeded(@transaction).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.transaction_succeeded') }
      it { @last_delivery.body.encoded.should include @transaction.user.name }
      it { @last_delivery.body.encoded.should include "Your latest SublimeVideo payment has been approved." }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/invoices/#{@invoice.to_param}" }
      it { @last_delivery.body.encoded.should include "If you have any questions, please email #{h I18n.t("mailer.billing.email")}." }
    end

    describe "#transaction_failed" do
      before(:all) do
        described_class.transaction_failed(@transaction).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.transaction_failed') }
      it { @last_delivery.body.encoded.should include @transaction.user.name }
      it { @last_delivery.body.encoded.should include "Your credit card could not be charged." }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/sites" }
      it { @last_delivery.body.encoded.should include "If you have any questions, please email #{h I18n.t("mailer.billing.email")}." }
    end

    describe "#too_many_charging_attempts" do
      before(:all) do
        described_class.too_many_charging_attempts(@invoice).deliver
        @last_delivery = ActionMailer::Base.deliveries.last
      end

      it { @last_delivery.subject.should eq   I18n.t('mailer.billing_mailer.too_many_charging_attempts', hostname: @invoice.site.hostname) }
      it { @last_delivery.body.encoded.should include "The payment for #{@invoice.site.hostname} has failed multiple times" }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/sites/#{@invoice.site.to_param}/plan/edit" }
      it { @last_delivery.body.encoded.should include "https://my.#{ActionMailer::Base.default_url_options[:host]}/account/billing/edit" }
      it { @last_delivery.body.encoded.should include "If you have any questions, please email #{h I18n.t("mailer.billing.email")}." }
    end
  end

end
