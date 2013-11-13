require 'spec_helper'

describe UserModules::CreditCard do

  describe "Factory" do
    describe "new record" do
      subject { build(:user_no_cc, valid_cc_attributes) }

      describe '#cc_type' do
        subject { super().cc_type }
        it        { should be_nil }
      end

      describe '#cc_last_digits' do
        subject { super().cc_last_digits }
        it { should be_nil }
      end

      describe '#cc_expire_on' do
        subject { super().cc_expire_on }
        it   { should be_nil }
      end

      describe '#cc_updated_at' do
        subject { super().cc_updated_at }
        it  { should be_nil }
      end

      describe '#cc_brand' do
        subject { super().cc_brand }
        it              { should eq 'visa' }
      end

      describe '#cc_full_name' do
        subject { super().cc_full_name }
        it          { should eq 'John Doe Huber' }
      end

      describe '#cc_number' do
        subject { super().cc_number }
        it             { should eq '4111111111111111' }
      end

      describe '#cc_expiration_year' do
        subject { super().cc_expiration_year }
        it    { should eq 1.year.from_now.year }
      end

      describe '#cc_expiration_month' do
        subject { super().cc_expiration_month }
        it   { should eq 1.year.from_now.month }
      end

      describe '#cc_verification_value' do
        subject { super().cc_verification_value }
        it { should eq '111' }
      end

      it { should be_valid }
      it { should_not be_credit_card }
      it { should_not be_pending_credit_card }
    end

    describe "persisted record with pending cc" do
      let(:user) {
        user = build(:user_no_cc, valid_cc_attributes)
        user.prepare_pending_credit_card
        user
      }
      subject { user }

      describe '#cc_type' do
        subject { super().cc_type }
        it        { should be_nil }
      end

      describe '#cc_last_digits' do
        subject { super().cc_last_digits }
        it { should be_nil }
      end

      describe '#cc_expire_on' do
        subject { super().cc_expire_on }
        it   { should be_nil }
      end

      describe '#cc_updated_at' do
        subject { super().cc_updated_at }
        it  { should be_nil }
      end

      describe '#pending_cc_type' do
        subject { super().pending_cc_type }
        it        { should eq 'visa' }
      end

      describe '#pending_cc_last_digits' do
        subject { super().pending_cc_last_digits }
        it { should eq '1111' }
      end

      describe '#pending_cc_expire_on' do
        subject { super().pending_cc_expire_on }
        it   { should eq 1.year.from_now.end_of_month.to_date }
      end

      describe '#pending_cc_updated_at' do
        subject { super().pending_cc_updated_at }
        it  { should be_present }
      end

      describe '#cc_brand' do
        subject { super().cc_brand }
        it              { should be_nil }
      end

      describe '#cc_full_name' do
        subject { super().cc_full_name }
        it          { should be_nil }
      end

      describe '#cc_number' do
        subject { super().cc_number }
        it             { should be_nil }
      end

      describe '#cc_expiration_year' do
        subject { super().cc_expiration_year }
        it    { should be_nil }
      end

      describe '#cc_expiration_month' do
        subject { super().cc_expiration_month }
        it   { should be_nil }
      end

      describe '#cc_verification_value' do
        subject { super().cc_verification_value }
        it { should be_nil }
      end

      it { should be_valid }
      it { should_not be_credit_card }
      it { should be_pending_credit_card }
    end

    describe "persisted record with cc_number == ''" do
      subject { build(:user_no_cc, valid_cc_attributes.merge(cc_number: '')) }

      describe '#cc_type' do
        subject { super().cc_type }
        it        { should be_nil }
      end

      describe '#cc_last_digits' do
        subject { super().cc_last_digits }
        it { should be_nil }
      end

      describe '#cc_expire_on' do
        subject { super().cc_expire_on }
        it   { should be_nil }
      end

      describe '#cc_updated_at' do
        subject { super().cc_updated_at }
        it  { should be_nil }
      end

      describe '#pending_cc_type' do
        subject { super().pending_cc_type }
        it        { should be_nil }
      end

      describe '#pending_cc_last_digits' do
        subject { super().pending_cc_last_digits }
        it { should be_nil }
      end

      describe '#pending_cc_expire_on' do
        subject { super().pending_cc_expire_on }
        it   { should be_nil }
      end

      describe '#pending_cc_updated_at' do
        subject { super().pending_cc_updated_at }
        it  { should be_nil }
      end

      describe '#cc_brand' do
        subject { super().cc_brand }
        it              { should eq 'visa' }
      end

      describe '#cc_full_name' do
        subject { super().cc_full_name }
        it          { should eq 'John Doe Huber' }
      end

      describe '#cc_number' do
        subject { super().cc_number }
        it             { should eq '' }
      end

      describe '#cc_expiration_year' do
        subject { super().cc_expiration_year }
        it    { should eq 1.year.from_now.year }
      end

      describe '#cc_expiration_month' do
        subject { super().cc_expiration_month }
        it   { should eq 1.year.from_now.month }
      end

      describe '#cc_verification_value' do
        subject { super().cc_verification_value }
        it { should eq '111' }
      end

      it { should be_valid }
      it { should_not be_credit_card }
      it { should_not be_pending_credit_card }
    end

    describe "persisted record with saved cc" do
      subject { create(:user) }

      describe '#cc_type' do
        subject { super().cc_type }
        it        { should eq 'visa' }
      end

      describe '#cc_last_digits' do
        subject { super().cc_last_digits }
        it { should eq '1111' }
      end

      describe '#cc_expire_on' do
        subject { super().cc_expire_on }
        it   { should eq 1.year.from_now.end_of_month.to_date }
      end

      describe '#cc_updated_at' do
        subject { super().cc_updated_at }
        it  { should be_present }
      end

      describe '#pending_cc_type' do
        subject { super().pending_cc_type }
        it        { should be_nil }
      end

      describe '#pending_cc_last_digits' do
        subject { super().pending_cc_last_digits }
        it { should be_nil }
      end

      describe '#pending_cc_expire_on' do
        subject { super().pending_cc_expire_on }
        it   { should be_nil }
      end

      describe '#pending_cc_updated_at' do
        subject { super().pending_cc_updated_at }
        it  { should be_nil }
      end

      describe '#cc_brand' do
        subject { super().cc_brand }
        it              { should be_nil }
      end

      describe '#cc_full_name' do
        subject { super().cc_full_name }
        it          { should be_nil }
      end

      describe '#cc_number' do
        subject { super().cc_number }
        it             { should be_nil }
      end

      describe '#cc_expiration_year' do
        subject { super().cc_expiration_year }
        it    { should be_nil }
      end

      describe '#cc_expiration_month' do
        subject { super().cc_expiration_month }
        it   { should be_nil }
      end

      describe '#cc_verification_value' do
        subject { super().cc_verification_value }
        it { should be_nil }
      end

      it { should be_valid }
      it { should be_credit_card }
      it { should_not be_pending_credit_card }
    end

    describe "persisted record with saved cc and with a new pending cc" do
      let(:user) {
        user = create(:user)
        user = User.find(user.id)
        user.attributes = valid_cc_attributes_master
        user.prepare_pending_credit_card
        user
      }
      subject { user }

      describe '#cc_type' do
        subject { super().cc_type }
        it        { should eq 'visa' }
      end

      describe '#cc_last_digits' do
        subject { super().cc_last_digits }
        it { should eq '1111' }
      end

      describe '#cc_expire_on' do
        subject { super().cc_expire_on }
        it   { should eq 1.year.from_now.end_of_month.to_date }
      end

      describe '#cc_updated_at' do
        subject { super().cc_updated_at }
        it  { should be_present }
      end

      describe '#pending_cc_type' do
        subject { super().pending_cc_type }
        it        { should eq 'master' }
      end

      describe '#pending_cc_last_digits' do
        subject { super().pending_cc_last_digits }
        it { should eq '9999' }
      end

      describe '#pending_cc_expire_on' do
        subject { super().pending_cc_expire_on }
        it   { should eq 2.years.from_now.end_of_month.to_date }
      end

      describe '#pending_cc_updated_at' do
        subject { super().pending_cc_updated_at }
        it  { should be_present }
      end

      describe '#cc_brand' do
        subject { super().cc_brand }
        it              { should be_nil }
      end

      describe '#cc_full_name' do
        subject { super().cc_full_name }
        it          { should be_nil }
      end

      describe '#cc_number' do
        subject { super().cc_number }
        it             { should be_nil }
      end

      describe '#cc_expiration_year' do
        subject { super().cc_expiration_year }
        it    { should be_nil }
      end

      describe '#cc_expiration_month' do
        subject { super().cc_expiration_month }
        it   { should be_nil }
      end

      describe '#cc_verification_value' do
        subject { super().cc_verification_value }
        it { should be_nil }
      end

      it { should be_valid }
      it { should be_credit_card }
      it { should be_pending_credit_card }
    end
  end

  describe "Validations" do
    it "allows no credit card given" do
      user = build(:user_no_cc)
      expect(user).to be_valid
    end

    it "allows valid credit card" do
      user = build(:user_no_cc, valid_cc_attributes)
      expect(user).to be_valid
    end

    describe "credit card brand" do
      it "doesn't allow brand that doesn't match the number" do
        user = build(:user_no_cc, valid_cc_attributes.merge(cc_brand: 'master'))
        expect(user).not_to be_valid
        expect(user.errors[:cc_brand]).to eq ["is invalid"]
      end

      it "doesn't allow invalid brand" do
        user = build(:user_no_cc, valid_cc_attributes.merge(cc_brand: '123'))
        expect(user).not_to be_valid
        expect(user.errors[:cc_brand]).to eq ["is invalid"]
      end
    end

    describe "credit card number" do
      it "doesn't validate if cc_number is not present" do
        user = build(:user_no_cc, valid_cc_attributes.merge(cc_number: ''))
        expect(user).to be_valid
      end

      it "validates cc_number" do
        user = build(:user_no_cc, valid_cc_attributes.merge(cc_number: '33'))
        expect(user).not_to be_valid
        expect(user.errors[:cc_number]).to eq ["is invalid"]
      end
    end

    describe "credit card expiration date" do
      it "doesn't allow expire date in the past" do
        user = build(:user_no_cc, valid_cc_attributes.merge(cc_expiration_month: 13, cc_expiration_year: 2010))
        expect(user).not_to be_valid
        expect(user.errors[:cc_expiration_month]).to be_empty
        expect(user.errors[:cc_expiration_year]).to eq ["expired"]
      end

      it "allows expire date in the future" do
        user = build(:user_no_cc, valid_cc_attributes.merge(cc_expiration_year: 3.years.from_now.year))
        expect(user).to be_valid
      end
    end

    describe "credit card full name" do
      it "doesn't allow blank" do
        user = build(:user_no_cc, valid_cc_attributes.merge(cc_full_name: nil))
        expect(user).not_to be_valid
        expect(user.errors[:cc_full_name]).to eq ["can't be blank"]
      end

      it "allows string" do
        user = build(:user_no_cc, valid_cc_attributes.merge(cc_full_name: "Jilion"))
        expect(user).to be_valid
      end
    end

    describe "credit card verification value" do
      it "doesn't allow blank" do
        user = build(:user_no_cc, valid_cc_attributes.merge(cc_verification_value: nil))
        expect(user).not_to be_valid
        expect(user.errors[:cc_verification_value]).to eq ["is required"]
      end
    end
  end

  describe "Instance Methods" do
    describe "#credit_card" do
      subject { build(:user_no_cc, valid_cc_attributes) }

      context "when attributes are present" do

        it "should return a ActiveMerchant::Billing::CreditCard instance" do
          first_credit_card = subject.credit_card
          expect(subject.credit_card).to eq first_credit_card

          expect(subject.credit_card).to be_an_instance_of(ActiveMerchant::Billing::CreditCard)
          expect(subject.credit_card.brand).to eq valid_cc_attributes[:cc_brand]
          expect(subject.credit_card.number).to eq valid_cc_attributes[:cc_number]
          expect(subject.credit_card.month).to eq valid_cc_attributes[:cc_expiration_month]
          expect(subject.credit_card.year).to eq valid_cc_attributes[:cc_expiration_year]
          expect(subject.credit_card.first_name).to eq valid_cc_attributes[:cc_full_name].split(' ').first
          expect(subject.credit_card.last_name).to eq valid_cc_attributes[:cc_full_name].split(' ').drop(1).join(" ")
          expect(subject.credit_card.verification_value).to eq valid_cc_attributes[:cc_verification_value]
        end

        it "should memoize the ActiveMerchant::Billing::CreditCard instance" do
          first_credit_card = subject.credit_card
          expect(subject.credit_card).to eq first_credit_card
        end

        describe "when new attributes are set" do
          it "should not memoize the first ActiveMerchant::Billing::CreditCard if new attributes are given" do
            first_credit_card = subject.credit_card
            expect(subject.credit_card).to eq first_credit_card
            subject.attributes = valid_cc_attributes_master
            subject.valid? # refresh the credit card

            expect(subject.credit_card).to be_an_instance_of(ActiveMerchant::Billing::CreditCard)
            expect(subject.credit_card).not_to eq first_credit_card
            expect(subject.credit_card.brand).to eq valid_cc_attributes_master[:cc_brand]
            expect(subject.credit_card.number).to eq valid_cc_attributes_master[:cc_number]
            expect(subject.credit_card.month).to eq valid_cc_attributes_master[:cc_expiration_month]
            expect(subject.credit_card.year).to eq valid_cc_attributes_master[:cc_expiration_year]
            expect(subject.credit_card.first_name).to eq valid_cc_attributes_master[:cc_full_name].split(' ').first
            expect(subject.credit_card.last_name).to eq valid_cc_attributes_master[:cc_full_name].split(' ').drop(1).join(" ")
            expect(subject.credit_card.verification_value).to eq valid_cc_attributes_master[:cc_verification_value]
          end
        end
      end

      context "when attributes are not present" do
        before { subject.attributes = nil_cc_attributes }

        it "should return a ActiveMerchant::Billing::CreditCard instance" do
          expect(subject.credit_card).to be_an_instance_of(ActiveMerchant::Billing::CreditCard)
        end
      end
    end

    describe "#cc_full_name=" do
      describe "on-word full name" do
        subject { build(:user_no_cc, cc_full_name: "John") }

        it { expect(subject.credit_card.first_name).to eq "John" }
        it { expect(subject.credit_card.last_name).to eq "-" }
      end

      describe "two-word full name" do
        subject { build(:user_no_cc, cc_full_name: "John Doe") }

        it { expect(subject.credit_card.first_name).to eq "John" }
        it { expect(subject.credit_card.last_name).to eq "Doe" }
      end

      describe "more-than-two-word full name" do
        subject { build(:user_no_cc, cc_full_name: "John Doe Bar") }

        it { expect(subject.credit_card.first_name).to eq "John" }
        it { expect(subject.credit_card.last_name).to eq "Doe Bar" }
      end
    end

    describe "#pending_credit_card?" do
      it { expect(create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now)).to be_pending_credit_card }
      it { expect(create(:user_no_cc, pending_cc_type: nil,    pending_cc_last_digits: '1234', pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now)).not_to be_pending_credit_card }
      it { expect(create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: nil,    pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now)).not_to be_pending_credit_card }
      it { expect(create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: nil, pending_cc_updated_at: Time.now)).not_to be_pending_credit_card }
      it { expect(create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: nil, pending_cc_updated_at: nil)).not_to be_pending_credit_card }
    end

    describe "#credit_card?" do
      it { expect(build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now)).to be_credit_card }
      it { expect(build(:user_no_cc, cc_type: nil,    cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now)).not_to be_credit_card }
      it { expect(build(:user_no_cc, cc_type: 'visa', cc_last_digits: nil,    cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now)).not_to be_credit_card }
      it { expect(build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: nil, cc_updated_at: Time.now)).not_to be_credit_card }
      it { expect(build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: nil)).not_to be_credit_card }
    end

    describe "#credit_card_expire_this_month? & #credit_card_expired?" do
      context "with no cc_expire_on" do
        subject { build(:user_no_cc, cc_expire_on: nil) }

        it { expect(subject).not_to be_credit_card }
        it { expect(subject.cc_expire_on).to be_nil }
        it { expect(subject).not_to be_credit_card_expire_this_month }
        it { expect(subject).not_to be_credit_card_expired }
      end

      context "with a credit card that will expire this month" do
        subject { create(:user, cc_expire_on: Time.now.utc.end_of_month.to_date) }

        it { expect(subject).to be_credit_card }
        it { expect(subject.cc_expire_on).to eq Time.now.utc.end_of_month.to_date }
        it { expect(subject).to be_credit_card_expire_this_month }
        it { expect(subject).not_to be_credit_card_expired }
      end

      context "with a credit card not expired" do
        subject { create(:user, cc_expire_on: 1.month.from_now.end_of_month.to_date) }

        it { expect(subject).to be_credit_card }
        it { expect(subject.cc_expire_on).to eq 1.month.from_now.end_of_month.to_date }
        it { expect(subject).not_to be_credit_card_expire_this_month }
        it { expect(subject).not_to be_credit_card_expired }
      end

      context "with a credit card expired" do
        subject { create(:user, cc_expire_on: 1.month.ago.end_of_month.to_date) }

        it { expect(subject).to be_credit_card }
        it { expect(subject.cc_expire_on).to eq 1.month.ago.end_of_month.to_date }
        it { expect(subject).not_to be_credit_card_expire_this_month }
        it { expect(subject).to be_credit_card_expired }
      end
    end

    describe "#prepare_pending_credit_card" do
      UserModules::CreditCard::BRANDS.each do |brand|
        context brand do
          let(:cc_attributes) { send "valid_cc_attributes_#{brand}" }
          let(:user) { build(:user_no_cc, cc_attributes) }

          it "saves all pending_cc_xxx fields" do
            expect(user.pending_cc_type).to be_nil
            expect(user.pending_cc_last_digits).to be_nil
            expect(user.pending_cc_expire_on).to be_nil
            expect(user.pending_cc_updated_at).to be_nil

            user.prepare_pending_credit_card

            expect(user.pending_cc_type).to eq cc_attributes[:cc_brand]
            expect(user.pending_cc_last_digits).to eq cc_attributes[:cc_number][-4,4]
            expect(user.pending_cc_expire_on).to eq Time.utc(cc_attributes[:cc_expiration_year], cc_attributes[:cc_expiration_month]).end_of_month.to_date
            expect(user.pending_cc_updated_at).to be_present
          end
        end
      end
    end

    describe "#reset_credit_card_info" do
      let(:user) { build(:user) }

      it "resets all pending_cc_xxx fields" do
        expect(user.cc_type).to be_present
        expect(user.cc_last_digits).to be_present
        expect(user.cc_expire_on).to be_present
        expect(user.cc_updated_at).to be_present

        user.reset_credit_card_info

        expect(user.reload.cc_type).to be_nil
        expect(user.cc_last_digits).to be_nil
        expect(user.cc_expire_on).to be_nil
        expect(user.cc_updated_at).to be_nil
      end
    end

    describe "#register_credit_card_on_file" do
      UserModules::CreditCard::BRANDS.each do |brand|
        let(:user) { build(:user_no_cc, send("valid_cc_attributes_#{brand}")) }

        it "should actually call OgoneWrapper" do
          user.prepare_pending_credit_card
          expect(OgoneWrapper).to receive(:store).with(user.credit_card, {
            billing_id: user.cc_alias,
            email: user.email,
            billing_address: { address1: user.billing_address_1, zip: user.billing_postal_code, city: user.billing_city, country: user.billing_country },
            d3d: true,
            paramplus: "CHECK_CC_USER_ID=#{user.id}"
          }) { double('authorize_response', params: {}) }
          user.register_credit_card_on_file
        end
      end
    end

    describe "#process_credit_card_authorization_response" do
      let(:d3d_params) { {
        "BRAND" => "American Express",
        "NCSTATUS" => "?",
        "STATUS" => "46",
        "PAYID" => "1234",
        "NCERRORPLUS" => "3D authentication needed",
        "HTML_ANSWER" => Base64.encode64("<html>No HTML.</html>")
      } }
      let(:authorized_params) { {
        "BRAND" => "American Express",
        "NCSTATUS" => "0",
        "STATUS" => "5",
        "PAYID" => "1234"
      } }
      let(:waiting_params) { {
        "BRAND" => "American Express",
        "NCSTATUS" => "0",
        "STATUS" => "51",
        "PAYID" => "1234",
        "NCERRORPLUS" => "Waiting"
      } }
      let(:invalid_params) { {
        "BRAND" => "American Express",
        "NCSTATUS" => "5",
        "STATUS" => "0",
        "PAYID" => "1234",
        "NCERRORPLUS" => "Invalid credit card number"
      } }
      let(:refused_params) { {
        "BRAND" => "American Express",
        "NCSTATUS" => "3",
        "STATUS" => "2",
        "PAYID" => "1234",
        "NCERRORPLUS" => "Refused credit card number"
      } }
      let(:canceled_params) { {
        "BRAND" => "American Express",
        "NCSTATUS" => "40001134",
        "STATUS" => "1",
        "PAYID" => "1234",
        "NCERRORPLUS" => "Authentication failed, please retry or cancel"
      } }
      let(:unknown_params) { {
        "BRAND" => "American Express",
        "NCSTATUS" => "2",
        "STATUS" => "52",
        "PAYID" => "1234",
        "NCERRORPLUS" => "Unknown error"
      } }

      context "user has no registered credit card" do
        before do
          @user = create(:user_no_cc)

          @user.attributes = valid_cc_attributes
          @user.credit_card(true) # reset credit card
          @user.prepare_pending_credit_card
          @user.cc_register = false # fake #register_credit_card_on_file

          expect(@user.cc_type).to be_nil
          expect(@user.cc_last_digits).to be_nil
          expect(@user.cc_expire_on).to be_nil
          expect(@user.cc_updated_at).to be_nil

          expect(@user.pending_cc_type).to eq 'visa'
          expect(@user.pending_cc_last_digits).to eq '1111'
          expect(@user.pending_cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
          expect(@user.pending_cc_updated_at).to be_present
        end
        subject { @user }

        context "authorization waiting for 3-D Secure identification" do
          it "sets the d3d_html attribute" do
            subject.process_credit_card_authorization_response(d3d_params)
            expect(subject.i18n_notice_and_alert).to be_nil
            expect(subject.d3d_html).to eq "<html>No HTML.</html>"

            expect(subject.cc_type).to be_nil
            expect(subject.cc_last_digits).to be_nil
            expect(subject.cc_expire_on).to be_nil
            expect(subject.cc_updated_at).to be_nil

            expect(subject.pending_cc_type).to eq 'visa'
            expect(subject.pending_cc_last_digits).to eq '1111'
            expect(subject.pending_cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).to be_present

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 46
            expect(subject.last_failed_cc_authorize_error).to eq "3D authentication needed"
          end
        end

        context "authorization is OK" do
          it "adds an error on base to the user" do
            expect(OgoneWrapper).to receive(:void).with("1234;RES")

            subject.process_credit_card_authorization_response(authorized_params)
            expect(subject.errors).to be_empty
            expect(subject.i18n_notice_and_alert).to be_nil
            expect(subject.d3d_html).to be_nil

            expect(subject.cc_type).to eq 'visa'
            expect(subject.cc_last_digits).to eq '1111'
            expect(subject.cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.cc_updated_at).to be_present

            expect(subject.pending_cc_type).to be_nil
            expect(subject.pending_cc_last_digits).to be_nil
            expect(subject.pending_cc_expire_on).to be_nil
            expect(subject.pending_cc_updated_at).to be_nil

            expect(subject.last_failed_cc_authorize_at).to be_nil
            expect(subject.last_failed_cc_authorize_status).to be_nil
            expect(subject.last_failed_cc_authorize_error).to be_nil
          end
        end

        context "authorization is waiting" do
          it "doesn't add an error on base to the user" do
            subject.process_credit_card_authorization_response(waiting_params)
            expect(subject.i18n_notice_and_alert).to eq({ notice: I18n.t("credit_card.errors.waiting") })
            expect(subject.d3d_html).to be_nil

            expect(subject.cc_type).to be_nil
            expect(subject.cc_last_digits).to be_nil
            expect(subject.cc_expire_on).to be_nil
            expect(subject.cc_updated_at).to be_nil

            expect(subject.pending_cc_type).to eq 'visa'
            expect(subject.pending_cc_last_digits).to eq '1111'
            expect(subject.pending_cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).to be_present

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 51
            expect(subject.last_failed_cc_authorize_error).to eq "Waiting"
          end
        end

        context "authorization is invalid or incomplete" do
          it "adds an error on base to the user" do
            subject.process_credit_card_authorization_response(invalid_params)
            expect(subject.i18n_notice_and_alert).to eq({ alert: I18n.t("credit_card.errors.invalid") })
            expect(subject.d3d_html).to be_nil

            expect(subject.pending_cc_type).to eq 'visa'
            expect(subject.pending_cc_last_digits).to eq '1111'
            expect(subject.pending_cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).to be_present
            expect(subject.cc_type).to be_nil
            expect(subject.cc_last_digits).to be_nil
            expect(subject.cc_expire_on).to be_nil
            expect(subject.cc_updated_at).to be_nil

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 0
            expect(subject.last_failed_cc_authorize_error).to eq "Invalid credit card number"
          end
        end

        context "authorization is refused" do
          it "adds an error on base to the user" do
            subject.process_credit_card_authorization_response(refused_params)
            expect(subject.i18n_notice_and_alert).to eq({ alert: I18n.t("credit_card.errors.refused") })
            expect(subject.d3d_html).to be_nil

            expect(subject.cc_type).to be_nil
            expect(subject.cc_last_digits).to be_nil
            expect(subject.cc_expire_on).to be_nil
            expect(subject.cc_updated_at).to be_nil

            expect(subject.pending_cc_type).to eq 'visa'
            expect(subject.pending_cc_last_digits).to eq '1111'
            expect(subject.pending_cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).to be_present

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 2
            expect(subject.last_failed_cc_authorize_error).to eq "Refused credit card number"
          end
        end

        context "authorization is canceled by client" do
          it "adds an error on base to the user" do
            subject.process_credit_card_authorization_response(canceled_params)
            expect(subject.errors).to be_empty
            expect(subject.i18n_notice_and_alert).to eq({ alert: I18n.t("credit_card.errors.canceled") })
            expect(subject.d3d_html).to be_nil

            expect(subject.cc_type).to be_nil
            expect(subject.cc_last_digits).to be_nil
            expect(subject.cc_expire_on).to be_nil
            expect(subject.cc_updated_at).to be_nil

            expect(subject.pending_cc_type).to eq 'visa'
            expect(subject.pending_cc_last_digits).to eq '1111'
            expect(subject.pending_cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).to be_present

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 1
            expect(subject.last_failed_cc_authorize_error).to eq "Authentication failed, please retry or cancel"
          end
        end

        context "authorization is  unknown" do
          it "doesn't add an error on base to the user" do
            expect(Notifier).to receive(:send).with("Credit card authorization for user ##{subject.id} (PAYID: 1234) has an uncertain state, please investigate quickly!")
            subject.process_credit_card_authorization_response(unknown_params)
            expect(subject.i18n_notice_and_alert).to eq({ alert: I18n.t("credit_card.errors.unknown") })
            expect(subject.d3d_html).to be_nil

            expect(subject.cc_type).to be_nil
            expect(subject.cc_last_digits).to be_nil
            expect(subject.cc_expire_on).to be_nil
            expect(subject.cc_updated_at).to be_nil

            expect(subject.pending_cc_type).to eq 'visa'
            expect(subject.pending_cc_last_digits).to eq '1111'
            expect(subject.pending_cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).to be_present

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 52
            expect(subject.last_failed_cc_authorize_error).to eq "Unknown error"
          end
        end
      end

      context "user has already a registered credit card" do
        before do
          @user = create(:user, cc_updated_at: 5.seconds.ago)

          @user.attributes = valid_cc_attributes_master
          @user.credit_card(true) # reset credit card
          @user.prepare_pending_credit_card
          @user.cc_register = false # fake #register_credit_card_on_file

          expect(@user.pending_cc_type).to eq 'master'
          expect(@user.pending_cc_last_digits).to eq '9999'
          expect(@user.pending_cc_expire_on).to eq 2.years.from_now.end_of_month.to_date
          expect(@user.pending_cc_updated_at).to be_present
          expect(@user.cc_type).to eq 'visa'
          expect(@user.cc_last_digits).to eq '1111'
          expect(@user.cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
          expect(@user.cc_updated_at).to be_present
          expect(@user.errors).to be_empty

          @first_cc_updated_at = @user.cc_updated_at
        end
        subject { @user }

        context "waiting for 3-D Secure identification" do
          it "should set d3d_html and save the user" do
            response = subject.process_credit_card_authorization_response(d3d_params)
            expect(response).to be_truthy
            expect(subject.errors).to be_empty
            expect(subject.i18n_notice_and_alert).to be_nil
            expect(subject.d3d_html).to eq "<html>No HTML.</html>"

            expect(subject.cc_type).to eq 'visa'
            expect(subject.cc_last_digits).to eq '1111'
            expect(subject.cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.cc_updated_at).to be_present

            expect(subject.pending_cc_type).to eq 'master'
            expect(subject.pending_cc_last_digits).to eq '9999'
            expect(subject.pending_cc_expire_on).to eq 2.years.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).not_to eq @first_cc_updated_at

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 46
            expect(subject.last_failed_cc_authorize_error).to eq "3D authentication needed"
          end
        end

        context "authorized" do
          it "should pend and apply pending cc info" do
            expect(OgoneWrapper).to receive(:void).with("1234;RES")
            subject.process_credit_card_authorization_response(authorized_params)
            expect(subject.i18n_notice_and_alert).to be_nil
            expect(subject.d3d_html).to be_nil

            expect(subject.pending_cc_type).to be_nil
            expect(subject.pending_cc_last_digits).to be_nil
            expect(subject.pending_cc_expire_on).to be_nil
            expect(subject.pending_cc_updated_at).to be_nil
            expect(subject.cc_type).to eq 'master'
            expect(subject.cc_last_digits).to eq '9999'
            expect(subject.cc_expire_on).to eq 2.years.from_now.end_of_month.to_date
            expect(subject.cc_updated_at).not_to eq @first_cc_updated_at

            expect(subject.last_failed_cc_authorize_at).to be_nil
            expect(subject.last_failed_cc_authorize_status).to be_nil
            expect(subject.last_failed_cc_authorize_error).to be_nil
          end
        end

        context "waiting" do
          it "should set a notice/alert, not reset pending cc info and save the user" do
            subject.process_credit_card_authorization_response(waiting_params)
            expect(subject.i18n_notice_and_alert).to eq({ notice: I18n.t("credit_card.errors.waiting") })
            expect(subject.d3d_html).to be_nil

            expect(subject.pending_cc_type).to eq 'master'
            expect(subject.pending_cc_last_digits).to eq '9999'
            expect(subject.pending_cc_expire_on).to eq 2.years.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at.to_i).not_to eq @first_cc_updated_at.to_i
            expect(subject.cc_type).to eq 'visa'
            expect(subject.cc_last_digits).to eq '1111'
            expect(subject.cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.cc_updated_at).to be_present

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 51
            expect(subject.last_failed_cc_authorize_error).to eq "Waiting"
          end
        end

        context "invalid or incomplete" do
          it "should set a notice/alert, reset pending cc info and save the user" do
            subject.process_credit_card_authorization_response(invalid_params)
            expect(subject.i18n_notice_and_alert).to eq({ alert: I18n.t("credit_card.errors.invalid") })
            expect(subject.d3d_html).to be_nil

            expect(subject.pending_cc_type).to eq 'master'
            expect(subject.pending_cc_last_digits).to eq '9999'
            expect(subject.pending_cc_expire_on).to eq 2.years.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).to be_present
            expect(subject.cc_type).to eq 'visa'
            expect(subject.cc_last_digits).to eq '1111'
            expect(subject.cc_expire_on).to eq 1.year.from_now.end_of_month.to_date

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 0
            expect(subject.last_failed_cc_authorize_error).to eq "Invalid credit card number"
            expect(subject.cc_updated_at.to_i).to eq @first_cc_updated_at.to_i
          end
        end

        context "refused" do
          it "should set a notice/alert, reset pending cc info and save the user" do
            subject.process_credit_card_authorization_response(refused_params)
            expect(subject.i18n_notice_and_alert).to eq({ alert: I18n.t("credit_card.errors.refused") })
            expect(subject.d3d_html).to be_nil

            expect(subject.pending_cc_type).to eq 'master'
            expect(subject.pending_cc_last_digits).to eq '9999'
            expect(subject.pending_cc_expire_on).to eq 2.years.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).to be_present
            expect(subject.cc_type).to eq 'visa'
            expect(subject.cc_last_digits).to eq '1111'
            expect(subject.cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.cc_updated_at.to_i).to eq @first_cc_updated_at.to_i

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 2
            expect(subject.last_failed_cc_authorize_error).to eq "Refused credit card number"
          end
        end

        context "unknown" do
          it "should set a notice/alert, not reset pending cc info, send a notification and save the user" do
            expect(Notifier).to receive(:send).with("Credit card authorization for user ##{subject.id} (PAYID: 1234) has an uncertain state, please investigate quickly!")
            subject.process_credit_card_authorization_response(unknown_params)
            expect(subject.i18n_notice_and_alert).to eq({ alert: I18n.t("credit_card.errors.unknown") })
            expect(subject.d3d_html).to be_nil

            expect(subject.pending_cc_type).to eq 'master'
            expect(subject.pending_cc_last_digits).to eq '9999'
            expect(subject.pending_cc_expire_on).to eq 2.years.from_now.end_of_month.to_date
            expect(subject.pending_cc_updated_at).to be_present
            expect(subject.cc_type).to eq 'visa'
            expect(subject.cc_last_digits).to eq '1111'
            expect(subject.cc_expire_on).to eq 1.year.from_now.end_of_month.to_date
            expect(subject.cc_updated_at).to be_present

            expect(subject.last_failed_cc_authorize_at).to be_present
            expect(subject.last_failed_cc_authorize_status).to eq 52
            expect(subject.last_failed_cc_authorize_error).to eq "Unknown error"
          end
        end
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
