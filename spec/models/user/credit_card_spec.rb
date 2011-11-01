require 'spec_helper'
require 'base64'

describe User::CreditCard do
  let(:user) { FactoryGirl.create(:user_real_cc) }

  describe "Factory" do
    describe "new record" do
      subject { FactoryGirl.build(:user_no_cc, valid_cc_attributes) }

      its(:cc_type)        { should be_nil }
      its(:cc_last_digits) { should be_nil }
      its(:cc_expire_on)   { should be_nil }
      its(:cc_updated_at)  { should be_nil }

      its(:cc_brand)              { should == 'visa' }
      its(:cc_full_name)          { should == 'John Doe Huber' }
      its(:cc_number)             { should == '4111111111111111' }
      its(:cc_expiration_year)    { should == 1.year.from_now.year }
      its(:cc_expiration_month)   { should == 1.year.from_now.month }
      its(:cc_verification_value) { should == '111' }

      it { should be_valid }
      it { should_not be_credit_card }
      it { should_not be_cc }
    end

    describe "persisted record with pending cc" do
      before(:all) do
        @user = FactoryGirl.create(:user_no_cc, valid_cc_attributes)
      end
      subject { @user }

      its(:cc_type)        { should be_nil }
      its(:cc_last_digits) { should be_nil }
      its(:cc_expire_on)   { should be_nil }
      its(:cc_updated_at)  { should be_nil }
      its(:pending_cc_type)        { should == 'visa' }
      its(:pending_cc_last_digits) { should == '1111' }
      its(:pending_cc_expire_on)   { should == 1.year.from_now.end_of_month.to_date }
      its(:pending_cc_updated_at)  { should be_present }

      its(:cc_brand)              { should be_nil }
      its(:cc_full_name)          { should be_nil }
      its(:cc_number)             { should be_nil }
      its(:cc_expiration_year)    { should be_nil }
      its(:cc_expiration_month)   { should be_nil }
      its(:cc_verification_value) { should be_nil }

      it { should be_valid }
      it { should_not be_credit_card }
      it { should_not be_cc }
    end

    describe "persisted record with saved cc" do
      before(:all) do
        @user = FactoryGirl.create(:user_no_cc, valid_cc_attributes)
        @user.apply_pending_credit_card_info
      end
      subject { @user }

      its(:cc_type)        { should == 'visa' }
      its(:cc_last_digits) { should == '1111' }
      its(:cc_expire_on)   { should == 1.year.from_now.end_of_month.to_date }
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
      it { should be_cc }
    end

    describe "persisted record with saved cc and with a new pending cc" do
      before(:all) do
        @user = FactoryGirl.create(:user_no_cc, valid_cc_attributes)
        @user.apply_pending_credit_card_info
        @user = User.find(@user.id)
        @user.update_attributes(valid_cc_attributes_master)
      end
      subject { @user }

      its(:cc_type)                { should == 'visa' }
      its(:cc_last_digits)         { should == '1111' }
      its(:cc_expire_on)           { should == 1.year.from_now.end_of_month.to_date }
      its(:cc_updated_at)          { should be_present }
      its(:pending_cc_type)        { should == 'master' }
      its(:pending_cc_last_digits) { should == '9999' }
      its(:pending_cc_expire_on)   { should == 2.years.from_now.end_of_month.to_date }
      its(:pending_cc_updated_at)  { should be_present }

      its(:cc_brand)              { should be_nil }
      its(:cc_full_name)          { should be_nil }
      its(:cc_number)             { should be_nil }
      its(:cc_expiration_year)    { should be_nil }
      its(:cc_expiration_month)   { should be_nil }
      its(:cc_verification_value) { should be_nil }

      it { should be_valid }
      it { should be_credit_card }
      it { should be_cc }
    end
  end

  describe "Validations" do
    it "allows no credit card given" do
      user = FactoryGirl.build(:user_no_cc)
      user.should be_valid
    end

    it "allows valid credit card" do
      user = FactoryGirl.build(:user_no_cc, valid_cc_attributes)
      user.should be_valid
    end

    describe "credit card brand" do
      it "doesn't allow brand that doesn't match the number" do
        user = FactoryGirl.build(:user_no_cc, valid_cc_attributes.merge(cc_brand: 'master'))
        user.should_not be_valid
        user.errors[:cc_brand].should == ["is invalid"]
      end

      it "doesn't allow invalid brand" do
        user = FactoryGirl.build(:user_no_cc, valid_cc_attributes.merge(cc_brand: '123'))
        user.should_not be_valid
        user.errors[:cc_brand].should == ["is invalid"]
      end
    end

    describe "credit card number" do
      it "validates cc_number presence" do
        user = FactoryGirl.build(:user_no_cc, valid_cc_attributes.merge(cc_number: nil))
        user.should_not be_valid
        user.errors[:cc_number].should == ["is invalid"]
      end

      it "validates cc_number" do
        user = FactoryGirl.build(:user_no_cc, valid_cc_attributes.merge(cc_number: '33'))
        user.should_not be_valid
        user.errors[:cc_number].should == ["is invalid"]
      end
    end

    describe "credit card expiration date" do
      it "doesn't allow expire date in the past" do
        user = FactoryGirl.build(:user_no_cc, valid_cc_attributes.merge(cc_expiration_month: 13, cc_expiration_year: 2010))
        user.should_not be_valid
        user.errors[:cc_expiration_month].should be_empty
        user.errors[:cc_expiration_year].should == ["expired", "is not a valid year"]
      end

      it "allows expire date in the future" do
        user = FactoryGirl.build(:user_no_cc, valid_cc_attributes.merge(cc_expiration_year: 3.years.from_now.year))
        user.should be_valid
      end
    end

    describe "credit card full name" do
      it "doesn't allow blank" do
        user = FactoryGirl.build(:user_no_cc, valid_cc_attributes.merge(cc_full_name: nil))
        user.should_not be_valid
        user.errors[:cc_full_name].should == ["can't be blank"]
      end

      it "allows string" do
        user = FactoryGirl.build(:user_no_cc, valid_cc_attributes.merge(cc_full_name: "Jime"))
        user.should be_valid
      end
    end

    describe "credit card verification value" do
      it "doesn't allow blank" do
        user = FactoryGirl.build(:user_no_cc, valid_cc_attributes.merge(cc_verification_value: nil))
        user.should_not be_valid
        user.errors[:cc_verification_value].should == ["is required"]
      end
    end
  end

  describe "Class Methods" do

    describe ".send_credit_card_expiration" do
      context "archived user" do
        it "doesn't send 'cc is expired' email when user's credit card will expire at the end of the current month" do
          @user = FactoryGirl.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year, state: 'archived'))
          @site = FactoryGirl.create(:site, user: @user)
          @user.cc_expire_on.should eql Time.now.utc.end_of_month.to_date
          expect { User::CreditCard.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end
      end

      context "not billable user" do
        it "doesn't send 'cc is expired' email when user's credit card will expire at the end of the current month" do
          @user = FactoryGirl.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year))
          @site = FactoryGirl.create(:site, user: @user, plan_id: @dev_plan.id)
          @user.cc_expire_on.should eql Time.now.utc.end_of_month.to_date
          expect { User::CreditCard.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end
      end

      context "billable user" do
        it "sends 'cc will expire' email when user's credit card will expire at the end of the current month" do
          @user = FactoryGirl.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year))
          @site = FactoryGirl.create(:site, user: @user)

          @user.cc_expire_on.should eql Time.now.utc.end_of_month.to_date
          expect { User::CreditCard.send_credit_card_expiration }.to change(ActionMailer::Base.deliveries, :size).by(1)
        end

        it "doesn't send 'cc is expired' email when user's credit card is expired 1 month ago" do
          Timecop.travel(1.month.ago) { @user = FactoryGirl.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year)) }
          @site = FactoryGirl.create(:site, user: @user)

          @user.cc_expire_on.should eql 1.month.ago.end_of_month.to_date
          expect { User::CreditCard.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end

        it "doesn't send 'cc is expired' email when user's credit card is expired 1 year ago" do
          Timecop.travel(1.year.ago) { @user = FactoryGirl.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year)) }
          @site = FactoryGirl.create(:site, user: @user)

          @user.cc_expire_on.should eql 1.year.ago.end_of_month.to_date
          expect { User::CreditCard.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end

        it "doesn't send expiration email when user's credit card will not expire at the end of the current month" do
          Timecop.travel(1.month.from_now) { @user = FactoryGirl.create(:user_real_cc, valid_cc_attributes.merge(cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year)) }
          @site = FactoryGirl.create(:site, user: @user)

          @user.cc_expire_on.should eql 1.month.from_now.end_of_month.to_date
          expect { User::CreditCard.send_credit_card_expiration }.to_not change(ActionMailer::Base.deliveries, :size)
        end
      end
    end

  end

  describe "Instance Methods" do

    describe "#credit_card" do
      context "when attributes are present" do
        subject { FactoryGirl.build(:user_no_cc, valid_cc_attributes) }

        it "should return a ActiveMerchant::Billing::CreditCard instance" do
          first_credit_card = subject.credit_card
          subject.credit_card.should == first_credit_card

          subject.credit_card.should be_an_instance_of(ActiveMerchant::Billing::CreditCard)
          subject.credit_card.type.should == valid_cc_attributes[:cc_brand]
          subject.credit_card.number.should == valid_cc_attributes[:cc_number]
          subject.credit_card.month.should == valid_cc_attributes[:cc_expiration_month]
          subject.credit_card.year.should == valid_cc_attributes[:cc_expiration_year]
          subject.credit_card.first_name.should == valid_cc_attributes[:cc_full_name].split(' ').first
          subject.credit_card.last_name.should == valid_cc_attributes[:cc_full_name].split(' ').drop(1).join(" ")
          subject.credit_card.verification_value.should == valid_cc_attributes[:cc_verification_value]
        end

        it "should memoize the ActiveMerchant::Billing::CreditCard instance" do
          first_credit_card = subject.credit_card
          subject.credit_card.should == first_credit_card
        end

        describe "when new attributes are set" do
          it "should not memoize the first ActiveMerchant::Billing::CreditCard if new attributes are given" do
            user = FactoryGirl.create(:user_no_cc, valid_cc_attributes)
            first_credit_card = user.credit_card
            user = User.find(user.id)
            user.attributes = valid_cc_attributes_master

            user.credit_card.should be_an_instance_of(ActiveMerchant::Billing::CreditCard)
            user.credit_card.should_not == first_credit_card
            user.credit_card.type.should == valid_cc_attributes_master[:cc_brand]
            user.credit_card.number.should == valid_cc_attributes_master[:cc_number]
            user.credit_card.month.should == valid_cc_attributes_master[:cc_expiration_month]
            user.credit_card.year.should == valid_cc_attributes_master[:cc_expiration_year]
            user.credit_card.first_name.should == valid_cc_attributes_master[:cc_full_name].split(' ').first
            user.credit_card.last_name.should == valid_cc_attributes_master[:cc_full_name].split(' ').drop(1).join(" ")
            user.credit_card.verification_value.should == valid_cc_attributes_master[:cc_verification_value]
          end
        end
      end

      context "when attributes are not present" do
        before(:each) { user.attributes = nil_cc_attributes }
        subject { user }

        it "should return a ActiveMerchant::Billing::CreditCard instance" do
          subject.credit_card.should be_an_instance_of(ActiveMerchant::Billing::CreditCard)
        end
      end
    end

    describe "#cc_full_name=" do
      describe "on-word full name" do
        subject { FactoryGirl.build(:user_no_cc, cc_full_name: "John") }

        it { subject.instance_variable_get("@cc_first_name").should == "John" }
        it { subject.instance_variable_get("@cc_last_name").should == "-" }
      end

      describe "two-word full name" do
        subject { FactoryGirl.build(:user_no_cc, cc_full_name: "John Doe") }

        it { subject.instance_variable_get("@cc_first_name").should == "John" }
        it { subject.instance_variable_get("@cc_last_name").should == "Doe" }
      end

      describe "more-than-two-word full name" do
        subject { FactoryGirl.build(:user_no_cc, cc_full_name: "John Doe Bar") }

        it { subject.instance_variable_get("@cc_first_name").should == "John" }
        it { subject.instance_variable_get("@cc_last_name").should == "Doe Bar" }
      end
    end

    describe "#cc_type" do
      it "should take cc_type from cc_number if nil" do
        FactoryGirl.create(:user_real_cc, cc_type: nil).cc_type.should == 'visa'
      end
    end

    describe "#any_credit_card_attributes_present?" do
      it { FactoryGirl.build(:user_no_cc).should_not be_any_credit_card_attributes_present }
      it { FactoryGirl.build(:user_no_cc, cc_number: 123).should be_any_credit_card_attributes_present }
      it { FactoryGirl.build(:user_no_cc, cc_full_name: "Foo Bar").should be_any_credit_card_attributes_present }
      it { FactoryGirl.build(:user_no_cc, cc_expiration_month: "foo").should be_any_credit_card_attributes_present }
      it { FactoryGirl.build(:user_no_cc, cc_expiration_year: "foo").should be_any_credit_card_attributes_present }
      it { FactoryGirl.build(:user_no_cc, cc_verification_value: "foo").should be_any_credit_card_attributes_present }
    end

    describe "#pending_credit_card?" do
      it { FactoryGirl.create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now).should be_pending_credit_card }
      it { FactoryGirl.create(:user_no_cc, pending_cc_type: nil,    pending_cc_last_digits: '1234', pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now).should_not be_pending_credit_card }
      it { FactoryGirl.create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: nil,    pending_cc_expire_on: Time.now.tomorrow, pending_cc_updated_at: Time.now).should_not be_pending_credit_card }
      it { FactoryGirl.create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: nil, pending_cc_updated_at: Time.now).should_not be_pending_credit_card }
      it { FactoryGirl.create(:user_no_cc, pending_cc_type: 'visa', pending_cc_last_digits: '1234', pending_cc_expire_on: nil, pending_cc_updated_at: nil).should_not be_pending_credit_card }
    end

    describe "#credit_card?" do
      it { FactoryGirl.build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now).should be_credit_card }
      it { FactoryGirl.build(:user_no_cc, cc_type: nil,    cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now).should_not be_credit_card }
      it { FactoryGirl.build(:user_no_cc, cc_type: 'visa', cc_last_digits: nil,    cc_expire_on: Time.now.tomorrow, cc_updated_at: Time.now).should_not be_credit_card }
      it { FactoryGirl.build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: nil, cc_updated_at: Time.now).should_not be_credit_card }
      it { FactoryGirl.build(:user_no_cc, cc_type: 'visa', cc_last_digits: '1234', cc_expire_on: Time.now.tomorrow, cc_updated_at: nil).should_not be_credit_card }
    end

    describe "#credit_card_expire_this_month?" do
      context "with no cc_expire_on" do
        subject { FactoryGirl.build(:user_no_cc, cc_expire_on: nil) }

        it { subject.cc_expire_on.should be_nil }
        it { subject.should_not be_credit_card_expire_this_month }
      end

      context "with a credit card that will expire this month" do
        subject { FactoryGirl.build(:user_no_cc, cc_expire_on: Time.now.utc.end_of_month.to_date) }

        it { subject.cc_expire_on.should == Time.now.utc.end_of_month.to_date }
        it { subject.should be_credit_card_expire_this_month }
      end

      context "with a credit card not expired" do
        subject { FactoryGirl.build(:user_no_cc, cc_expire_on: 1.month.from_now.end_of_month.to_date) }

        it { subject.cc_expire_on.should == 1.month.from_now.end_of_month.to_date }
        it { subject.should_not be_credit_card_expire_this_month }
      end

      context "with a credit card expired" do
        subject { FactoryGirl.build(:user_no_cc, cc_expire_on: 1.month.ago.end_of_month.to_date) }

        it { subject.cc_expire_on.should == 1.month.ago.end_of_month.to_date }
        it { subject.should_not be_credit_card_expire_this_month }
      end
    end

    describe "#credit_card_expired?" do
      context "with no cc_expire_on" do
        subject { FactoryGirl.create(:user_no_cc, cc_expiration_month: nil, cc_expiration_year: nil) }

        it { subject.cc_expire_on.should be_nil }
        it { subject.should_not be_credit_card_expired }
      end

      context "with a credit card that will expire this month" do
        subject { FactoryGirl.create(:user_real_cc, cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year) }

        it { subject.cc_expire_on.should == Time.now.utc.end_of_month.to_date }
        it { subject.should_not be_credit_card_expired }
      end

      context "with a credit card not expired" do
        subject { FactoryGirl.create(:user_real_cc, cc_expiration_month: 1.month.from_now.month, cc_expiration_year: 1.month.from_now.year) }

        it { subject.cc_expire_on.should == 1.month.from_now.end_of_month.to_date }
        it { subject.should_not be_credit_card_expired }
      end

      context "with a credit card expired" do
        subject { Timecop.travel(1.month.ago) { @user = FactoryGirl.create(:user_real_cc, cc_expiration_month: Time.now.utc.month, cc_expiration_year: Time.now.utc.year) }; @user }

        it { subject.cc_expire_on.should == 1.month.ago.end_of_month.to_date }
        it { subject.should be_credit_card_expired }
      end
    end

    describe "#pend_credit_card_info" do
      describe "when cc attributes present" do
        subject { FactoryGirl.build(:user_no_cc, valid_cc_attributes) }
        before(:each) { subject.pend_credit_card_info; subject.save; subject.reload; }

        its(:cc_type)        { should be_nil }
        its(:cc_last_digits) { should be_nil }
        its(:cc_expire_on)   { should be_nil }
        its(:pending_cc_type)        { should == 'visa' }
        its(:pending_cc_last_digits) { should == '1111' }
        its(:pending_cc_expire_on)   { should == 1.year.from_now.end_of_month.to_date}
      end
    end

    describe "#apply_pending_credit_card_info" do
      before(:all) do
        @user = FactoryGirl.create(:user_no_cc, valid_cc_attributes)
      end
      subject { @user.reload.apply_pending_credit_card_info; @user }

      its(:cc_type)                { should == 'visa' }
      its(:cc_last_digits)         { should == '1111' }
      its(:cc_expire_on)           { should == 1.year.from_now.end_of_month.to_date }
      its(:cc_updated_at)          { should be_present }
      its(:pending_cc_type)        { should be_nil }
      its(:pending_cc_last_digits) { should be_nil }
      its(:pending_cc_expire_on)   { should be_nil }
      its(:pending_cc_updated_at)  { should be_nil }
    end

    describe "#check_credit_card" do
      use_vcr_cassette "ogone/void_authorization"
      subject { user }

      it "should actually call Ogone" do
        Ogone.should_receive(:authorize).with(100, user.credit_card, {
          store: user.cc_alias,
          email: user.email,
          billing_address: { zip: user.postal_code, country: user.country },
          d3d: true,
          paramplus: "CHECK_CC_USER_ID=#{user.id}"
        }) { mock('authorize_response', :params => {}) }
        subject.check_credit_card
      end
    end

    describe "#process_cc_authorize_and_save" do
      before(:all) do
        @d3d_params = {
          "NCSTATUS" => "?",
          "STATUS" => "46",
          "PAYID" => "1234",
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
          "PAYID" => "1234"
        }
        @invalid_params = {
          "NCSTATUS" => "5",
          "STATUS" => "0",
          "PAYID" => "1234"
        }
        @refused_params = {
          "NCSTATUS" => "3",
          "STATUS" => "2",
          "PAYID" => "1234"
        }
        @unknown_params = {
          "NCSTATUS" => "2",
          "STATUS" => "52",
          "PAYID" => "1234"
        }
      end

      context "user has no registered credit card" do
        before(:each) do
          @user = FactoryGirl.create(:user_no_cc)

          @user.cc_type.should be_nil
          @user.cc_last_digits.should be_nil
          @user.cc_expire_on.should be_nil
          @user.cc_updated_at.should be_nil

          @user.attributes = valid_cc_attributes

          @user.cc_type.should be_nil
          @user.cc_last_digits.should be_nil
          @user.cc_expire_on.should be_nil
          @user.cc_updated_at.should be_nil
          @user.errors.should be_empty
        end
        subject { @user.save; @user }

        context "waiting for 3-D Secure identification" do
          it "should return true and set d3d_html" do
            subject.process_cc_authorize_and_save(@d3d_params)
            subject.i18n_notice_and_alert.should be_nil
            subject.d3d_html.should == "<html>No HTML.</html>"

            subject.reload
            subject.pending_cc_type.should == 'visa'
            subject.pending_cc_last_digits.should == '1111'
            subject.pending_cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil
          end
        end

        context "authorized" do
          it "should not add an error on base to the user" do
            subject.pending_cc_type.should == 'visa'
            subject.pending_cc_last_digits.should == '1111'
            subject.pending_cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present

            subject.should_receive(:void_authorization).with("1234;RES")

            subject.process_cc_authorize_and_save(@authorized_params)
            subject.errors.should be_empty
            subject.i18n_notice_and_alert.should be_nil
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should be_nil
            subject.pending_cc_last_digits.should be_nil
            subject.pending_cc_expire_on.should be_nil
            subject.pending_cc_updated_at.should be_nil
            subject.cc_type.should == 'visa'
            subject.cc_last_digits.should == '1111'
            subject.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.should be_present
          end
        end

        context "waiting" do
          it "should not add an error on base to the user" do
            subject.process_cc_authorize_and_save(@waiting_params)
            subject.i18n_notice_and_alert.should == { notice: I18n.t("credit_card.errors.waiting") }
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should == 'visa'
            subject.pending_cc_last_digits.should == '1111'
            subject.pending_cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil
          end
        end

        context "invalid or incomplete" do
          it "returns a hash with infos" do
            subject.process_cc_authorize_and_save(@invalid_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.invalid") }
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should == 'visa'
            subject.pending_cc_last_digits.should == '1111'
            subject.pending_cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil
          end
        end

        context "refused" do
          it "should add an error on base to the user" do
            subject.process_cc_authorize_and_save(@refused_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.refused") }
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should == 'visa'
            subject.pending_cc_last_digits.should == '1111'
            subject.pending_cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil
          end
        end

        context "not known" do
          it "should not add an error on base to the user" do
            Notify.should_receive(:send).with("Credit card authorization for user ##{subject.id} (PAYID: 1234) has an uncertain state, please investigate quickly!")
            subject.process_cc_authorize_and_save(@unknown_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.unknown") }
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should == 'visa'
            subject.pending_cc_last_digits.should == '1111'
            subject.pending_cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should be_nil
            subject.cc_last_digits.should be_nil
            subject.cc_expire_on.should be_nil
            subject.cc_updated_at.should be_nil
          end
        end
      end

      context "user has already a registered credit card" do
        before(:each) do
          @user = FactoryGirl.create(:user)
          @user.cc_type.should == 'visa'
          @user.cc_last_digits.should == '1111'
          @user.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
          @user.cc_updated_at.should be_present
          @first_cc_updated_at = @user.cc_updated_at
          @user.errors.should be_empty

          @user.attributes = valid_cc_attributes_master
        end
        subject { @user.save; @user }

        context "waiting for 3-D Secure identification" do
          it "should set d3d_html and save the user" do
            subject.pending_cc_type.should == 'master'
            subject.pending_cc_last_digits.should == '9999'
            subject.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present

            response = subject.process_cc_authorize_and_save(@d3d_params)
            response.should be_true
            subject.errors.should be_empty
            subject.i18n_notice_and_alert.should be_nil
            subject.d3d_html.should == "<html>No HTML.</html>"

            subject.reload
            subject.pending_cc_type.should == 'master'
            subject.pending_cc_last_digits.should == '9999'
            subject.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should_not == @first_cc_updated_at
            subject.cc_type.should == 'visa'
            subject.cc_last_digits.should == '1111'
            subject.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.should be_present
          end
        end

        context "authorized" do
          it "should pend and apply pending cc infos" do
            subject.should_receive(:void_authorization).with("1234;RES")
            subject.process_cc_authorize_and_save(@authorized_params)
            subject.i18n_notice_and_alert.should be_nil
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should be_nil
            subject.pending_cc_last_digits.should be_nil
            subject.pending_cc_expire_on.should be_nil
            subject.pending_cc_updated_at.should be_nil
            subject.cc_type.should == 'master'
            subject.cc_last_digits.should == '9999'
            subject.cc_expire_on.should == 2.years.from_now.end_of_month.to_date
            subject.cc_updated_at.should_not eql @first_cc_updated_at
          end
        end

        context "waiting" do
          it "should set a has of notice/alert, not reset pending cc infos and save the user" do
            subject.process_cc_authorize_and_save(@waiting_params)
            subject.i18n_notice_and_alert.should == { notice: I18n.t("credit_card.errors.waiting") }
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should == 'master'
            subject.pending_cc_last_digits.should == '9999'
            subject.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.to_i.should_not == @first_cc_updated_at.to_i
            subject.cc_type.should == 'visa'
            subject.cc_last_digits.should == '1111'
            subject.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.should be_present
          end
        end

        context "invalid or incomplete" do
          it "should set a has of notice/alert, reset pending cc infos and save the user" do
            subject.process_cc_authorize_and_save(@invalid_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.invalid") }
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should == 'master'
            subject.pending_cc_last_digits.should == '9999'
            subject.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should == 'visa'
            subject.cc_last_digits.should == '1111'
            subject.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.to_i.should == @first_cc_updated_at.to_i
          end
        end

        context "refused" do
          it "should set a has of notice/alert, reset pending cc infos and save the user" do
            subject.process_cc_authorize_and_save(@refused_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.refused") }
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should == 'master'
            subject.pending_cc_last_digits.should == '9999'
            subject.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should == 'visa'
            subject.cc_last_digits.should == '1111'
            subject.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.to_i.should == @first_cc_updated_at.to_i
          end
        end

        context "unknown" do
          it "should set a has of notice/alert, not reset pending cc infos, send a notification and save the user" do
            Notify.should_receive(:send).with("Credit card authorization for user ##{subject.id} (PAYID: 1234) has an uncertain state, please investigate quickly!")
            subject.process_cc_authorize_and_save(@unknown_params)
            subject.i18n_notice_and_alert.should == { alert: I18n.t("credit_card.errors.unknown") }
            subject.d3d_html.should be_nil

            subject.reload
            subject.pending_cc_type.should == 'master'
            subject.pending_cc_last_digits.should == '9999'
            subject.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
            subject.pending_cc_updated_at.should be_present
            subject.cc_type.should == 'visa'
            subject.cc_last_digits.should == '1111'
            subject.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
            subject.cc_updated_at.should be_present
          end
        end
      end

    end

    # Private method
    describe "#void_authorization" do
      use_vcr_cassette "ogone/void_authorization"
      before(:each) { user.update_attributes(valid_cc_attributes) }
      subject { user }

      it "should void authorization after verification" do
        mock_response = mock('response', :success? => true)
        Ogone.should_receive(:void) { mock_response }
        subject.send(:void_authorization, "1234;RES")
      end

      it "should notify if void authorization after verification failed" do
        mock_response = mock('response', :success? => false, :message => 'failed')
        Ogone.stub(:void) { mock_response }
        Notify.should_receive(:send)
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
