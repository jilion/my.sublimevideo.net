require 'spec_helper'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('lib/service/credit_card')

describe Service::CreditCard do
  let(:user) { create(:user) }

  describe ".send_credit_card_expiration_email" do
    let(:public_addon_plan_paid) { create(:addon_plan, availability: 'public', price: 995) }

    before do
      @user_no_cc        = create(:user, cc_type: nil, cc_last_digits: nil)
      create(:billable_item, site: create(:site, user: @user_no_cc), item: public_addon_plan_paid, state: 'subscribed', created_at: 1.months.ago)

      @user_cc           = create(:user)
      create(:billable_item, site: create(:site, user: @user_cc), item: public_addon_plan_paid, state: 'subscribed', created_at: 1.months.ago)

      @user_cc_will_expire = create(:user, cc_expire_on: Time.now.utc.end_of_month.to_date)
      create(:billable_item, site: create(:site, user: @user_cc_will_expire), item: public_addon_plan_paid, state: 'subscribed', created_at: 1.months.ago)

      @user_cc_valid_and_last_credit_card_expiration_notice = create(:user, last_credit_card_expiration_notice_sent_at: 30.days.ago)
      create(:billable_item, site: create(:site, user: @user_cc_valid_and_last_credit_card_expiration_notice), item: public_addon_plan_paid, state: 'subscribed', created_at: 1.months.ago)

      @user_cc_will_expire_and_last_credit_card_expiration_notice_1 = create(:user, cc_expire_on: Time.now.utc.end_of_month.to_date, last_credit_card_expiration_notice_sent_at: 30.days.ago)
      create(:billable_item, site: create(:site, user: @user_cc_will_expire_and_last_credit_card_expiration_notice_1), item: public_addon_plan_paid, state: 'subscribed', created_at: 1.months.ago)

      @user_cc_will_expire_and_last_credit_card_expiration_notice_2 = create(:user, cc_expire_on: Time.now.utc.end_of_month.to_date, last_credit_card_expiration_notice_sent_at: 14.days.ago)
      create(:billable_item, site: create(:site, user: @user_cc_will_expire_and_last_credit_card_expiration_notice_2), item: public_addon_plan_paid, state: 'subscribed', created_at: 1.months.ago)
    end

    it "sends 'cc will expire' email when user's credit card will expire at the end of the current month and the last notice he received is at least 15 days old" do
      expect { described_class.send_credit_card_expiration_email }.to change(Sidekiq::Worker.jobs, :size).by(1)
    end

    it "sends 'cc will expire' email to the right user" do
      BillingMailer.should delay(:credit_card_will_expire).with(@user_cc_will_expire_and_last_credit_card_expiration_notice_1.id)

      described_class.send_credit_card_expiration_email
    end
  end


end
