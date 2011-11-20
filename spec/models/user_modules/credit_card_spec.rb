require 'spec_helper'
require 'base64'

describe UserModules::CreditCard do

  describe "Factory" do
    describe "new record" do
      subject { Factory.build(:user_no_cc, valid_cc_attributes) }

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

    describe "persisted record with pending cc" do
      before(:all) do
        @user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_register: '0'))
        @user.prepare_pending_credit_card
      end
      subject { @user }

      its(:cc_type)        { should be_nil }
      its(:cc_last_digits) { should be_nil }
      its(:cc_expire_on)   { should be_nil }
      its(:cc_updated_at)  { should be_nil }

      its(:pending_cc_type)        { should eq 'visa' }
      its(:pending_cc_last_digits) { should eq '1111' }
      its(:pending_cc_expire_on)   { should eq 1.year.from_now.end_of_month.to_date }
      its(:pending_cc_updated_at)  { should be_present }

      its(:cc_brand)              { should be_nil }
      its(:cc_full_name)          { should be_nil }
      its(:cc_number)             { should be_nil }
      its(:cc_expiration_year)    { should be_nil }
      its(:cc_expiration_month)   { should be_nil }
      its(:cc_verification_value) { should be_nil }

      it { should be_valid }
      it { should_not be_credit_card }
      it { should be_pending_credit_card }
    end

    describe "persisted record with cc_number == ''" do
      before(:all) do
        @user = Factory.create(:user_real_cc, cc_number: '')
      end
      subject { @user }

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

    describe "persisted record with cc_register == '0'" do
      before(:all) do
        @user = Factory.create(:user_real_cc, cc_register: false)
      end
      subject { @user }

      its(:cc_type)        { should be_nil }
      its(:cc_last_digits) { should be_nil }
      its(:cc_expire_on)   { should be_nil }
      its(:cc_updated_at)  { should be_nil }

      its(:pending_cc_type)        { should eq 'visa' }
      its(:pending_cc_last_digits) { should eq '1111' }
      its(:pending_cc_expire_on)   { should eq 1.year.from_now.end_of_month.to_date }
      its(:pending_cc_updated_at)  { should be_present }

      its(:cc_brand)              { should be_nil }
      its(:cc_full_name)          { should be_nil }
      its(:cc_number)             { should be_nil }
      its(:cc_expiration_year)    { should be_nil }
      its(:cc_expiration_month)   { should be_nil }
      its(:cc_verification_value) { should be_nil }

      it { should be_valid }
      it { should_not be_credit_card }
      it { should be_pending_credit_card }
    end

    describe "persisted record with saved cc" do
      before(:all) do
        @user = Factory.create(:user_real_cc)
      end
      subject { @user }

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

    describe "persisted record with saved cc and with a new pending cc" do
      before(:all) do
        @user = Factory.create(:user_real_cc)
        @user = User.find(@user.id)
        @user.assign_attributes(valid_cc_attributes_master)
        @user.prepare_pending_credit_card
      end
      subject { @user }

      its(:cc_type)        { should eq 'visa' }
      its(:cc_last_digits) { should eq '1111' }
      its(:cc_expire_on)   { should eq 1.year.from_now.end_of_month.to_date }
      its(:cc_updated_at)  { should be_present }

      its(:pending_cc_type)        { should eq 'master' }
      its(:pending_cc_last_digits) { should eq '9999' }
      its(:pending_cc_expire_on)   { should eq 2.years.from_now.end_of_month.to_date }
      its(:pending_cc_updated_at)  { should be_present }

      its(:cc_brand)              { should be_nil }
      its(:cc_full_name)          { should be_nil }
      its(:cc_number)             { should be_nil }
      its(:cc_expiration_year)    { should be_nil }
      its(:cc_expiration_month)   { should be_nil }
      its(:cc_verification_value) { should be_nil }

      it { should be_valid }
      it { should be_credit_card }
      it { should be_pending_credit_card }
    end
  end

  describe "Validations" do
    it "allows no credit card given" do
      user = Factory.build(:user_no_cc)
      user.should be_valid
    end

    it "allows valid credit card" do
      user = Factory.build(:user_no_cc, valid_cc_attributes)
      user.should be_valid
    end

    describe "credit card brand" do
      it "doesn't allow brand that doesn't match the number" do
        user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_brand: 'master'))
        user.should_not be_valid
        user.errors[:cc_brand].should eq ["is invalid"]
      end

      it "doesn't allow invalid brand" do
        user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_brand: '123'))
        user.should_not be_valid
        user.errors[:cc_brand].should eq ["is invalid"]
      end
    end

    describe "credit card number" do
      it "doesn't validate if cc_number is not presence" do
        user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_number: nil))
        user.should be_valid
      end

      it "validates cc_number" do
        user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_number: '33'))
        user.should_not be_valid
        user.errors[:cc_number].should eq ["is invalid"]
      end
    end

    describe "credit card expiration date" do
      it "doesn't allow expire date in the past" do
        user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_expiration_month: 13, cc_expiration_year: 2010))
        user.should_not be_valid
        user.errors[:cc_expiration_month].should be_empty
        user.errors[:cc_expiration_year].should eq ["expired"]
      end

      it "allows expire date in the future" do
        user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_expiration_year: 3.years.from_now.year))
        user.should be_valid
      end
    end

    describe "credit card full name" do
      it "doesn't allow blank" do
        user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_full_name: nil))
        user.should_not be_valid
        user.errors[:cc_full_name].should eq ["can't be blank"]
      end

      it "allows string" do
        user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_full_name: "Jilion"))
        user.should be_valid
      end
    end

    describe "credit card verification value" do
      it "doesn't allow blank" do
        user = Factory.build(:user_no_cc, valid_cc_attributes.merge(cc_verification_value: nil))
        user.should_not be_valid
        user.errors[:cc_verification_value].should eq ["is required"]
      end
    end
  end

  describe "Class Methods" do

    describe ".send_credit_card_expiration" do
      context "archived user" do
        it "doesn't send 'cc is expired' email when user's credit card will expire at the end of the current month" do
          @user = Factory.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year, state: 'archived'))
          @site = Factory.create(:site, user: @user)
          @user.cc_expire_on.should eq Time.now.utc.end_of_month.to_date
          expect { User.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end
      end

      context "not billable user" do
        it "doesn't send 'cc is expired' email when user's credit card will expire at the end of the current month" do
          @user = Factory.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year))
          @site = Factory.create(:site, user: @user, plan_id: @free_plan.id)
          @user.cc_expire_on.should eq Time.now.utc.end_of_month.to_date
          expect { User.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end
      end

      context "billable user" do
        it "sends 'cc will expire' email when user's credit card will expire at the end of the current month" do
          @user = Factory.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year))
          @site = Factory.create(:site, user: @user)

          @user.cc_expire_on.should eq Time.now.utc.end_of_month.to_date
          expect { User.send_credit_card_expiration }.to change(ActionMailer::Base.deliveries, :size).by(1)
        end

        it "doesn't send 'cc is expired' email when user's credit card is expired 1 month ago" do
          Timecop.travel(1.month.ago) { @user = Factory.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year)) }
          @site = Factory.create(:site, user: @user)

          @user.cc_expire_on.should eq 1.month.ago.end_of_month.to_date
          expect { User.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end

        it "doesn't send 'cc is expired' email when user's credit card is expired 1 year ago" do
          Timecop.travel(1.year.ago) { @user = Factory.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year)) }
          @site = Factory.create(:site, user: @user)

          @user.cc_expire_on.should eq 1.year.ago.end_of_month.to_date
          expect { User.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end

        it "doesn't send expiration email when user's credit card will not expire at the end of the current month" do
          Timecop.travel(1.month.from_now) { @user = Factory.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year)) }
          @site = Factory.create(:site, user: @user)

          @user.cc_expire_on.should eq 1.month.from_now.end_of_month.to_date
          expect { User.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end
      end
    end

  end

  describe "Instance Methods" do

    describe "#credit_card" do
      subject { Factory.build(:user_no_cc, valid_cc_attributes) }

      context "when attributes are present" do

        it "should return a ActiveMerchant::Billing::CreditCard instance" do
          first_credit_card = subject.credit_card
          subject.credit_card.should eq first_credit_card

          subject.credit_card.should be_an_instance_of(ActiveMerchant::Billing::CreditCard)
          subject.credit_card.type.should eq valid_cc_attributes[:cc_brand]
          subject.credit_card.number.should eq valid_cc_attributes[:cc_number]
          subject.credit_card.month.should eq valid_cc_attributes[:cc_expiration_month]
          subject.credit_card.year.should eq valid_cc_attributes[:cc_expiration_year]
          subject.credit_card.first_name.should eq valid_cc_attributes[:cc_full_name].split(' ').first
          subject.credit_card.last_name.should eq valid_cc_attributes[:cc_full_name].split(' ').drop(1).join(" ")
          subject.credit_card.verification_value.should eq valid_cc_attributes[:cc_verification_value]
        end

        it "should memoize the ActiveMerchant::Billing::CreditCard instance" do
          first_credit_card = subject.credit_card
          subject.credit_card.should eq first_credit_card
        end

        describe "when new attributes are set" do
          it "should not memoize the first ActiveMerchant::Billing::CreditCard if new attributes are given" do
            first_credit_card = subject.credit_card
            subject.credit_card.should eq first_credit_card
            subject.attributes = valid_cc_attributes_master
            subject.valid? # refresh the credit card

            subject.credit_card.should be_an_instance_of(ActiveMerchant::Billing::CreditCard)
            subject.credit_card.should_not eq first_credit_card
            subject.credit_card.type.should eq valid_cc_attributes_master[:cc_brand]
            subject.credit_card.number.should eq valid_cc_attributes_master[:cc_number]
            subject.credit_card.month.should eq valid_cc_attributes_master[:cc_expiration_month]
            subject.credit_card.year.should eq valid_cc_attributes_master[:cc_expiration_year]
            subject.credit_card.first_name.should eq valid_cc_attributes_master[:cc_full_name].split(' ').first
            subject.credit_card.last_name.should eq valid_cc_attributes_master[:cc_full_name].split(' ').drop(1).join(" ")
            subject.credit_card.verification_value.should eq valid_cc_attributes_master[:cc_verification_value]
          end
        end
      end

      context "when attributes are not present" do
        before(:each) { subject.attributes = nil_cc_attributes }

        it "should return a ActiveMerchant::Billing::CreditCard instance" do
          subject.credit_card.should be_an_instance_of(ActiveMerchant::Billing::CreditCard)
        end
      end
    end

    describe "#cc_full_name=" do
      describe "on-word full name" do
        subject { Factory.build(:user_no_cc, cc_full_name: "John") }

        it { subject.instance_variable_get("@cc_first_name").should eq "John" }
        it { subject.instance_variable_get("@cc_last_name").should eq "-" }
      end

      describe "two-word full name" do
        subject { Factory.build(:user_no_cc, cc_full_name: "John Doe") }

        it { subject.instance_variable_get("@cc_first_name").should eq "John" }
        it { subject.instance_variable_get("@cc_last_name").should eq "Doe" }
      end

      describe "more-than-two-word full name" do
        subject { Factory.build(:user_no_cc, cc_full_name: "John Doe Bar") }

        it { subject.instance_variable_get("@cc_first_name").should eq "John" }
        it { subject.instance_variable_get("@cc_last_name").should eq "Doe Bar" }
      end
    end

    describe "#cc_type" do
      it "should take cc_type from cc_number if nil" do
        Factory.create(:user_real_cc, cc_register: 1, cc_type: nil).cc_type.should eq 'visa'
      end
    end

    describe "#pending_credit_card?" do
      it { Factory.create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now).should be_pending_credit_card }
      it { Factory.create(:user_no_cc, pending_cc_type: nil,    pending_cc_last_digits: '1234', pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now).should_not be_pending_credit_card }
      it { Factory.create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: nil,    pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now).should_not be_pending_credit_card }
      it { Factory.create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: nil, pending_cc_updated_at: Time.now).should_not be_pending_credit_card }
      it { Factory.create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: nil, pending_cc_updated_at: nil).should_not be_pending_credit_card }
    end

    describe "#credit_card?" do
      it { Factory.build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now).should be_credit_card }
      it { Factory.build(:user_no_cc, cc_type: nil,    cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now).should_not be_credit_card }
      it { Factory.build(:user_no_cc, cc_type: 'visa', cc_last_digits: nil,    cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now).should_not be_credit_card }
      it { Factory.build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: nil, cc_updated_at: Time.now).should_not be_credit_card }
      it { Factory.build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: nil).should_not be_credit_card }
    end

    describe "#credit_card_expire_this_month? & #credit_card_expired?" do
      context "with no cc_expire_on" do
        subject { Factory.build(:user_no_cc, cc_expire_on: nil) }

        it { subject.should_not be_credit_card }
        it { subject.cc_expire_on.should be_nil }
        it { subject.should_not be_credit_card_expire_this_month }
        it { subject.should_not be_credit_card_expired }
      end

      context "with a credit card that will expire this month" do
        subject { Factory.create(:user_real_cc).tap { |u| u.cc_expire_on = Time.now.utc.end_of_month.to_date } }

        it { subject.should be_credit_card }
        it { subject.cc_expire_on.should eq Time.now.utc.end_of_month.to_date }
        it { subject.should be_credit_card_expire_this_month }
        it { subject.should_not be_credit_card_expired }
      end

      context "with a credit card not expired" do
        subject { Factory.create(:user_real_cc).tap { |u| u.cc_expire_on = 1.month.from_now.end_of_month.to_date } }

        it { subject.should be_credit_card }
        it { subject.cc_expire_on.should eq 1.month.from_now.end_of_month.to_date }
        it { subject.should_not be_credit_card_expire_this_month }
        it { subject.should_not be_credit_card_expired }
      end

      context "with a credit card expired" do
        subject { Factory.create(:user_real_cc).tap { |u| u.cc_expire_on = 1.month.ago.end_of_month.to_date } }

        it { subject.should be_credit_card }
        it { subject.cc_expire_on.should eq 1.month.ago.end_of_month.to_date }
        it { subject.should_not be_credit_card_expire_this_month }
        it { subject.should be_credit_card_expired }
      end
    end

    describe "#prepare_pending_credit_card" do
      describe "when cc attributes present" do
        subject { Factory.build(:user_no_cc, valid_cc_attributes) }

        it "saves all pending_cc_xxx fields" do
          subject.pending_cc_type.should be_nil
          subject.pending_cc_last_digits.should be_nil
          subject.pending_cc_expire_on.should be_nil
          subject.pending_cc_updated_at.should be_nil

          subject.prepare_pending_credit_card

          subject.pending_cc_type.should be_present
          subject.pending_cc_last_digits.should be_present
          subject.pending_cc_expire_on.should be_present
          subject.pending_cc_updated_at.should be_present
        end
      end
    end

    describe "#reset_credit_card_infos" do
      subject { Factory.build(:user) }

      it "resets all pending_cc_xxx fields" do
        subject.cc_type.should be_present
        subject.cc_last_digits.should be_present
        subject.cc_expire_on.should be_present
        subject.cc_updated_at.should be_present

        subject.reset_credit_card_infos

        subject.reload
        subject.cc_type.should be_nil
        subject.cc_last_digits.should be_nil
        subject.cc_expire_on.should be_nil
        subject.cc_updated_at.should be_nil
      end
    end

    describe "#apply_pending_credit_card_info" do
      before(:each) do
        @user = Factory.build(:user_no_cc, valid_cc_attributes)
        @user.prepare_pending_credit_card
        @user.cc_register = false # fake #register_credit_card_on_file
      end
      subject { @user }

      it "sets cc_xxx fields and resets all pending_cc_xxx and last_failed_cc_authorize_xxx fields" do
        subject.pending_cc_type.should be_present
        subject.pending_cc_last_digits.should be_present
        subject.pending_cc_expire_on.should be_present
        subject.pending_cc_updated_at.should be_present
        subject.cc_type.should be_nil
        subject.cc_last_digits.should be_nil
        subject.cc_expire_on.should be_nil
        subject.cc_updated_at.should be_nil

        subject.apply_pending_credit_card_info

        subject.reload
        subject.pending_cc_type.should be_nil
        subject.pending_cc_last_digits.should be_nil
        subject.pending_cc_expire_on.should be_nil
        subject.pending_cc_updated_at.should be_nil

        subject.cc_type.should be_present
        subject.cc_last_digits.should be_present
        subject.cc_expire_on.should be_present
        subject.cc_updated_at.should be_present

        subject.last_failed_cc_authorize_at.should be_nil
        subject.last_failed_cc_authorize_status.should be_nil
        subject.last_failed_cc_authorize_error.should be_nil
      end
    end

    describe "#register_credit_card_on_file" do
      use_vcr_cassette "ogone/void_authorization"
      subject { Factory.build(:user_no_cc, valid_cc_attributes) }

      it "should actually call Ogone" do
        Ogone.should_receive(:authorize).with(100, subject.credit_card, {
          store: subject.cc_alias,
          email: subject.email,
          billing_address: { address1: subject.billing_address_1, zip: subject.billing_postal_code, city: subject.billing_city, country: subject.billing_country },
          d3d: true,
          paramplus: "CHECK_CC_USER_ID=#{subject.id}"
        }) { mock('authorize_response', params: {}) }
        subject.register_credit_card_on_file
      end
    end

    describe "#process_credit_card_authorization_response" do
      before(:all) do
        @d3d_params = {
          "NCSTATUS" => "?",
          "STATUS" => "46",
          "PAYID" => "1234",
          "NCERRORPLUS" => "3D authentication needed",
          "HTML_ANSWER" => Base64.encode64("<html>No HTML.</html>")
        }
        @authorized_params = {
          "NCSTATUS" => "0",
          "STATUS" => "5",
          "PAYID" => "1234"
        }
        @waiting_params = {
          "NCSTATUS" => "0",
          "STATUS" => "51",
          "PAYID" => "1234",
          "NCERRORPLUS" => "Waiting"
        }
        @invalid_params = {
          "NCSTATUS" => "5",
          "STATUS" => "0",
          "PAYID" => "1234",
          "NCERRORPLUS" => "Invalid credit card number"
        }
        @refused_params = {
          "NCSTATUS" => "3",
          "STATUS" => "2",
          "PAYID" => "1234",
          "NCERRORPLUS" => "Refused credit card number"
        }
        @unknown_params = {
          "NCSTATUS" => "2",
          "STATUS" => "52",
          "PAYID" => "1234",
          "NCERRORPLUS" => "Unknown error"
        }
      end

      context "user has no registered credit card" do
        before(:each) do
          @user = Factory.create(:user_no_cc)

          @user.attributes = valid_cc_attributes
          @user.prepare_pending_credit_card
          @user.cc_register = false # fake #register_credit_card_on_file

          @user.cc_type.should be_nil
          @user.cc_last_digits.should be_nil
          @user.cc_expire_on.should be_nil
          @user.cc_updated_at.should be_nil

          @user.pending_cc_type.should eq 'visa'
          @user.pending_cc_last_digits.should eq '1111'
          @user.pending_cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
          @user.pending_cc_updated_at.should be_present
        end
        subject { @user }

        context "authorization waiting for 3-D Secure identification" do
          it "should return true and set d3d_html" do
            subject.process_credit_card_authorization_response(@d3d_params)
            subject.i18n_notice_and_alert.should be_nil
            subject.d3d_html.should eq "<html>No HTML.</html>"

            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil

            subject.pending_cc_type.should eq 'visa'
            subject.pending_cc_last_digits.should eq '1111'
            subject.pending_cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 46
            subject.last_failed_cc_authorize_error.should eq "3D authentication needed"
          end
        end

        context "authorization is OK" do
          it "should not add an error on base to the user" do
            subject.should_receive(:void_authorization).with("1234;RES")

            subject.process_credit_card_authorization_response(@authorized_params)
            subject.errors.should be_empty
            subject.i18n_notice_and_alert.should be_nil
            subject.d3d_html.should be_nil

            subject.cc_type.should eq 'visa'
            subject.cc_last_digits.should eq '1111'
            subject.cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.should be_present

            subject.pending_cc_type.should be_nil
            subject.pending_cc_last_digits.should be_nil
            subject.pending_cc_expire_on.should be_nil
            subject.pending_cc_updated_at.should be_nil

            subject.last_failed_cc_authorize_at.should be_nil
            subject.last_failed_cc_authorize_status.should be_nil
            subject.last_failed_cc_authorize_error.should be_nil
          end
        end

        context "authorization is waiting" do
          it "should not add an error on base to the user" do
            subject.process_credit_card_authorization_response(@waiting_params)
            subject.i18n_notice_and_alert.should == { notice: I18n.t("credit_card.errors.waiting") }
            subject.d3d_html.should be_nil

            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil

            subject.pending_cc_type.should eq 'visa'
            subject.pending_cc_last_digits.should eq '1111'
            subject.pending_cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 51
            subject.last_failed_cc_authorize_error.should eq "Waiting"
          end
        end

        context "authorization is invalid or incomplete" do
          it "returns a hash with infos" do
            subject.process_credit_card_authorization_response(@invalid_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.invalid") }
            subject.d3d_html.should be_nil

            subject.pending_cc_type.should eq 'visa'
            subject.pending_cc_last_digits.should eq '1111'
            subject.pending_cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 0
            subject.last_failed_cc_authorize_error.should eq "Invalid credit card number"
          end
        end

        context "authorization is refused" do
          it "should add an error on base to the user" do
            subject.process_credit_card_authorization_response(@refused_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.refused") }
            subject.d3d_html.should be_nil
            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil

            subject.pending_cc_type.should eq 'visa'
            subject.pending_cc_last_digits.should eq '1111'
            subject.pending_cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 2
            subject.last_failed_cc_authorize_error.should eq "Refused credit card number"
          end
        end

        context "authorization is  unknown" do
          it "should not add an error on base to the user" do
            Notify.should_receive(:send).with("Credit card authorization for user ##{subject.id} (PAYID: 1234) has an uncertain state, please investigate quickly!")
            subject.process_credit_card_authorization_response(@unknown_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.unknown") }
            subject.d3d_html.should be_nil

            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil

            subject.pending_cc_type.should eq 'visa'
            subject.pending_cc_last_digits.should eq '1111'
            subject.pending_cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 52
            subject.last_failed_cc_authorize_error.should eq "Unknown error"
          end
        end
      end

      context "user has already a registered credit card" do
        before(:each) do
          @user = Factory.create(:user, cc_updated_at: 5.seconds.ago)

          @user.attributes = valid_cc_attributes_master
          @user.prepare_pending_credit_card
          @user.cc_register = false # fake #register_credit_card_on_file

          @user.pending_cc_type.should eq 'master'
          @user.pending_cc_last_digits.should eq '9999'
          @user.pending_cc_expire_on.should eq 2.years.from_now.end_of_month.to_date
          @user.pending_cc_updated_at.should be_present
          @user.cc_type.should eq 'visa'
          @user.cc_last_digits.should eq '1111'
          @user.cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
          @user.cc_updated_at.should be_present
          @user.errors.should be_empty

          @first_cc_updated_at = @user.cc_updated_at
        end
        subject { @user }

        context "waiting for 3-D Secure identification" do
          it "should set d3d_html and save the user" do
            response = subject.process_credit_card_authorization_response(@d3d_params)
            response.should be_true
            subject.errors.should be_empty
            subject.i18n_notice_and_alert.should be_nil
            subject.d3d_html.should eq "<html>No HTML.</html>"

            subject.cc_type.should eq 'visa'
            subject.cc_last_digits.should eq '1111'
            subject.cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.should be_present

            subject.pending_cc_type.should eq 'master'
            subject.pending_cc_last_digits.should eq '9999'
            subject.pending_cc_expire_on.should eq 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should_not eq @first_cc_updated_at

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 46
            subject.last_failed_cc_authorize_error.should eq "3D authentication needed"
          end
        end

        context "authorized" do
          it "should pend and apply pending cc infos" do
            subject.should_receive(:void_authorization).with("1234;RES")
            subject.process_credit_card_authorization_response(@authorized_params)
            subject.i18n_notice_and_alert.should be_nil
            subject.d3d_html.should be_nil

            subject.pending_cc_type.should be_nil
            subject.pending_cc_last_digits.should be_nil
            subject.pending_cc_expire_on.should be_nil
            subject.pending_cc_updated_at.should be_nil
            subject.cc_type.should eq 'master'
            subject.cc_last_digits.should eq '9999'
            subject.cc_expire_on.should eq 2.years.from_now.end_of_month.to_date
            subject.cc_updated_at.should_not eq @first_cc_updated_at

            subject.last_failed_cc_authorize_at.should be_nil
            subject.last_failed_cc_authorize_status.should be_nil
            subject.last_failed_cc_authorize_error.should be_nil
          end
        end

        context "waiting" do
          it "should set a notice/alert, not reset pending cc infos and save the user" do
            subject.process_credit_card_authorization_response(@waiting_params)
            subject.i18n_notice_and_alert.should == { notice: I18n.t("credit_card.errors.waiting") }
            subject.d3d_html.should be_nil

            subject.pending_cc_type.should eq 'master'
            subject.pending_cc_last_digits.should eq '9999'
            subject.pending_cc_expire_on.should eq 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.to_i.should_not eq @first_cc_updated_at.to_i
            subject.cc_type.should eq 'visa'
            subject.cc_last_digits.should eq '1111'
            subject.cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.should be_present

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 51
            subject.last_failed_cc_authorize_error.should eq "Waiting"
          end
        end

        context "invalid or incomplete" do
          it "should set a notice/alert, reset pending cc infos and save the user" do
            subject.process_credit_card_authorization_response(@invalid_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.invalid") }
            subject.d3d_html.should be_nil

            subject.pending_cc_type.should eq 'master'
            subject.pending_cc_last_digits.should eq '9999'
            subject.pending_cc_expire_on.should eq 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should eq 'visa'
            subject.cc_last_digits.should eq '1111'
            subject.cc_expire_on.should eq 1.year.from_now.end_of_month.to_date

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 0
            subject.last_failed_cc_authorize_error.should eq "Invalid credit card number"
            subject.cc_updated_at.to_i.should eq @first_cc_updated_at.to_i
          end
        end

        context "refused" do
          it "should set a notice/alert, reset pending cc infos and save the user" do
            subject.process_credit_card_authorization_response(@refused_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.refused") }
            subject.d3d_html.should be_nil

            subject.pending_cc_type.should eq 'master'
            subject.pending_cc_last_digits.should eq '9999'
            subject.pending_cc_expire_on.should eq 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should eq 'visa'
            subject.cc_last_digits.should eq '1111'
            subject.cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.to_i.should eq @first_cc_updated_at.to_i

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 2
            subject.last_failed_cc_authorize_error.should eq "Refused credit card number"
          end
        end

        context "unknown" do
          it "should set a notice/alert, not reset pending cc infos, send a notification and save the user" do
            Notify.should_receive(:send).with("Credit card authorization for user ##{subject.id} (PAYID: 1234) has an uncertain state, please investigate quickly!")
            subject.process_credit_card_authorization_response(@unknown_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.unknown") }
            subject.d3d_html.should be_nil

            subject.pending_cc_type.should eq 'master'
            subject.pending_cc_last_digits.should eq '9999'
            subject.pending_cc_expire_on.should eq 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should eq 'visa'
            subject.cc_last_digits.should eq '1111'
            subject.cc_expire_on.should eq 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.should be_present

            subject.last_failed_cc_authorize_at.should be_present
            subject.last_failed_cc_authorize_status.should eq 52
            subject.last_failed_cc_authorize_error.should eq "Unknown error"
          end
        end
      end

    end

    # Private method
    describe "#void_authorization" do
      subject { Factory.create(:user_real_cc) }

      it "voids authorization after verification" do
        mock_response = mock('response', :success? => true)
        Ogone.should_receive(:void).twice { mock_response }
        subject.send(:void_authorization, "1234;RES")
      end

      it "notifies if void authorization after verification failed" do
        mock_response = mock('response', :success? => false, message:'failed')
        Ogone.stub(:void) { mock_response }
        Notify.should_receive(:send).twice
        subject.send(:void_authorization, "1234;RES")
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
