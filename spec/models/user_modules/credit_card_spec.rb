require 'spec_helper'

describe UserModules::CreditCard do

  describe "Factory" do
    describe "new record" do
      subject { build(:user_no_cc, valid_cc_attributes) }

      its(:cc_type)        { should be_nil }
      its(:cc_last_digits) { should be_nil }
      its(:cc_expire_on)   { should be_nil }
      its(:cc_updated_at)  { should be_nil }

      its(:cc_brand)              { should eq 'visa' }
      its(:cc_full_name)          { should eq 'John Doe Huber' }
      its(:cc_number)             { should eq '4111111111111111' }
      its(:cc_expiration_year)    { should eq 1.year.from_now.year }
      its(:cc_expiration_month)   { should eq 1.year.from_now.month }
      its(:cc_verification_value) { should eq '111' }

      it { should be_valid }
      it { should_not be_credit_card }
      it { should_not be_pending_credit_card }
    end

    describe "persisted record with cc_number == ''" do
      subject { build(:user_no_cc, valid_cc_attributes.merge(cc_number: '')) }

      its(:cc_type)        { should be_nil }
      its(:cc_last_digits) { should be_nil }
      its(:cc_expire_on)   { should be_nil }
      its(:cc_updated_at)  { should be_nil }

      its(:pending_cc_type)        { should be_nil }
      its(:pending_cc_last_digits) { should be_nil }
      its(:pending_cc_expire_on)   { should be_nil }
      its(:pending_cc_updated_at)  { should be_nil }

      its(:cc_brand)              { should eq 'visa' }
      its(:cc_full_name)          { should eq 'John Doe Huber' }
      its(:cc_number)             { should eq '' }
      its(:cc_expiration_year)    { should eq 1.year.from_now.year }
      its(:cc_expiration_month)   { should eq 1.year.from_now.month }
      its(:cc_verification_value) { should eq '111' }

      it { should be_valid }
      it { should_not be_credit_card }
      it { should_not be_pending_credit_card }
    end

    describe "persisted record with saved cc" do
      subject { create(:user) }

      its(:cc_type)        { should eq 'visa' }
      its(:cc_last_digits) { should eq '1111' }
      its(:cc_expire_on)   { should eq 1.year.from_now.end_of_month.to_date }
      its(:cc_updated_at)  { should be_present }

      its(:pending_cc_type)        { should be_nil }
      its(:pending_cc_last_digits) { should be_nil }
      its(:pending_cc_expire_on)   { should be_nil }
      its(:pending_cc_updated_at)  { should be_nil }

      its(:cc_brand)              { should be_nil }
      its(:cc_full_name)          { should be_nil }
      its(:cc_number)             { should be_nil }
      its(:cc_expiration_year)    { should be_nil }
      its(:cc_expiration_month)   { should be_nil }
      its(:cc_verification_value) { should be_nil }

      it { should be_valid }
      it { should be_credit_card }
      it { should_not be_pending_credit_card }
    end
  end

  describe "Instance Methods" do
    describe "#pending_credit_card?" do
      it { create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now).should be_pending_credit_card }
      it { create(:user_no_cc, pending_cc_type: nil,    pending_cc_last_digits: '1234', pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now).should_not be_pending_credit_card }
      it { create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: nil,    pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now).should_not be_pending_credit_card }
      it { create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: nil, pending_cc_updated_at: Time.now).should_not be_pending_credit_card }
      it { create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: nil, pending_cc_updated_at: nil).should_not be_pending_credit_card }
    end

    describe "#credit_card?" do
      it { build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now).should be_credit_card }
      it { build(:user_no_cc, cc_type: nil,    cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now).should_not be_credit_card }
      it { build(:user_no_cc, cc_type: 'visa', cc_last_digits: nil,    cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now).should_not be_credit_card }
      it { build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: nil, cc_updated_at: Time.now).should_not be_credit_card }
      it { build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: nil).should_not be_credit_card }
    end

    describe "#credit_card_expire_this_month? & #credit_card_expired?" do
      context "with no cc_expire_on" do
        subject { build(:user_no_cc, cc_expire_on: nil) }

        it { subject.should_not be_credit_card }
        it { subject.cc_expire_on.should be_nil }
        it { subject.should_not be_credit_card_expire_this_month }
        it { subject.should_not be_credit_card_expired }
      end

      context "with a credit card that will expire this month" do
        subject { create(:user, cc_expire_on: Time.now.utc.end_of_month.to_date) }

        it { subject.should be_credit_card }
        it { subject.cc_expire_on.should eq Time.now.utc.end_of_month.to_date }
        it { subject.should be_credit_card_expire_this_month }
        it { subject.should_not be_credit_card_expired }
      end

      context "with a credit card not expired" do
        subject { create(:user, cc_expire_on: 1.month.from_now.end_of_month.to_date) }

        it { subject.should be_credit_card }
        it { subject.cc_expire_on.should eq 1.month.from_now.end_of_month.to_date }
        it { subject.should_not be_credit_card_expire_this_month }
        it { subject.should_not be_credit_card_expired }
      end

      context "with a credit card expired" do
        subject { create(:user, cc_expire_on: 1.month.ago.end_of_month.to_date) }

        it { subject.should be_credit_card }
        it { subject.cc_expire_on.should eq 1.month.ago.end_of_month.to_date }
        it { subject.should_not be_credit_card_expire_this_month }
        it { subject.should be_credit_card_expired }
      end
    end

  end

end

# == Schema Information
#
# Table name: users
#
#  cc_type              :string(255)
#  cc_last_digits       :integer
#  cc_expire_on         :date
#  cc_updated_at        :datetime
#
