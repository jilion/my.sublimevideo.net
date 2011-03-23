# == Schema Information
#
# Table name: users
#
#  cc_type              :string(255)
#  cc_last_digits       :integer
#  cc_expire_on         :date
#  cc_updated_at        :datetime
#

require 'spec_helper'
require 'base64'

describe User::CreditCard do
  let(:user) { Factory(:user) }

  describe "Factory" do
    use_vcr_cassette "ogone/credit_card_visa_validation"
    before(:each) { user.update_attributes(valid_cc_attributes) }
    subject { user }

    its(:cc_type)         { should == 'visa' }
    its(:cc_last_digits)  { should == "1111" }
    its(:cc_expire_on)    { should == 1.year.from_now.end_of_month.to_date }
    its(:cc_updated_at)   { should be_present }

    it { should be_valid }
    it { should be_credit_card }
    it { should be_cc }
  end

  describe "Validations" do
    it "should validates cc_type" do
      user.attributes = valid_cc_attributes.merge(:cc_type => 'master')
      user.should_not be_valid
      user.errors[:cc_type].should be_present
    end
    it "should validates cc_type if not matching cc_number" do
      user.attributes = valid_cc_attributes.merge(:cc_number => '5399999999999999')
      user.should_not be_valid
      user.errors[:cc_type].should be_present
    end
    it "should validates cc_type if matching cc_number" do
      VCR.use_cassette('ogone/credit_card_master_validation') do
        user.attributes = valid_cc_attributes.merge(:cc_number => '5399999999999999', :cc_type => 'master')
        user.should be_valid
      end
    end
    it "should validates cc_number presence" do
      user.attributes = valid_cc_attributes.merge(:cc_number => nil)
      user.should_not be_valid
      user.errors[:cc_number].should be_present
    end
    it "should validates cc_number" do
      user.attributes = valid_cc_attributes.merge(:cc_number => '33')
      user.should_not be_valid
      user.errors[:cc_number].should be_present
    end
    it "should validates cc_expire_on" do
      user.attributes = valid_cc_attributes.merge(:cc_expire_on => 50.years.ago)
      user.should_not be_valid
      user.errors[:cc_expire_on].should be_present
    end
    it "should validates cc_full_name presence" do
      user.attributes = valid_cc_attributes.merge(:cc_full_name => nil)
      user.should_not be_valid
      user.errors[:cc_full_name].should be_present
    end
    it "should validates cc_full_name presence" do
      user.attributes = valid_cc_attributes.merge(:cc_full_name => "Jime")
      user.should be_valid
    end
    it "should validates cc_verification_value presence" do
      user.attributes = valid_cc_attributes.merge(:cc_verification_value => nil)
      user.should_not be_valid
      user.errors[:cc_verification_value].should be_present
    end
  end

  describe "Class Methods" do

    describe ".send_credit_card_expiration" do
      it "should send 'cc will expire' email when user's credit card will expire at the end of the current month" do
        user.update_attribute(:cc_expire_on, Time.now.utc)
        lambda { User::CreditCard.send_credit_card_expiration }.should change(ActionMailer::Base.deliveries, :size).by(1)
      end
      it "should not send 'cc is expired' email when user's credit card is expired 1 month ago" do
        user.update_attribute(:cc_expire_on, 1.month.ago)
        lambda { User::CreditCard.send_credit_card_expiration }.should_not change(ActionMailer::Base.deliveries, :size)
      end
      it "should not send 'cc is expired' email when user's credit card is expired 1 year ago" do
        user.update_attribute(:cc_expire_on, 1.year.ago)
        lambda { User::CreditCard.send_credit_card_expiration }.should_not change(ActionMailer::Base.deliveries, :size)
      end
      it "should not send expiration email when user's credit card will not expire at the end of the current month" do
        user.update_attribute(:cc_expire_on, 1.month.from_now)
        lambda { User::CreditCard.send_credit_card_expiration }.should_not change(ActionMailer::Base.deliveries, :size)
      end
    end

  end

  describe "Instance Methods" do

    describe "#cc_expire_on=" do
      use_vcr_cassette "ogone/credit_card_visa_validation"

      it "should set cc_expire_on to nil" do
        user.update_attributes(valid_cc_attributes.merge(:cc_expire_on => nil))
        user.cc_expire_on.should == nil
      end

      it "should set cc_expire_on to the end of month" do
        user.update_attributes(valid_cc_attributes.merge(:cc_expire_on => Time.utc(2010,1,15)))
        user.cc_expire_on.should == Time.utc(2010,1,15).end_of_month.to_date
      end
    end

    describe "#cc_type" do
      use_vcr_cassette "ogone/credit_card_visa_validation"
      before(:each) { user.update_attributes(valid_cc_attributes.merge(:cc_type => nil)) }

      it "should take cc_type from cc_number if nil" do
        user.cc_type.should == 'visa'
      end
    end

    describe "#credit_card_expire_this_month?" do
      context "with no cc_expire_on" do
        before(:each) { user }

        specify { user.cc_expire_on.should be_nil }
        specify { user.should_not be_credit_card_expire_this_month }
      end

      context "with a credit card that will expire this month" do
        before(:each) { user.update_attributes(valid_cc_attributes.merge(:cc_expire_on => Time.now.utc)) }

        specify { user.cc_expire_on.should == Time.now.utc.end_of_month.to_date }
        specify { user.should be_credit_card_expire_this_month }
      end

      context "with a credit card not expired" do
        before(:each) { user.update_attributes(valid_cc_attributes.merge(:cc_expire_on => 1.month.from_now)) }

        specify { user.cc_expire_on.should == 1.month.from_now.end_of_month.to_date }
        specify { user.should_not be_credit_card_expire_this_month }
      end

      context "with a credit card expired" do
        before(:each) { user.update_attributes(valid_cc_attributes.merge(:cc_expire_on => 1.month.ago)) }

        specify { user.cc_expire_on.should == 1.month.ago.end_of_month.to_date }
        specify { user.should_not be_credit_card_expire_this_month }
      end
    end

    describe "#credit_card_expired?" do
      context "with no cc_expire_on" do
        before(:each) { user }

        specify { user.cc_expire_on.should be_nil }
        specify { user.should_not be_credit_card_expired }
      end

      context "with a credit card not expired" do
        before(:each) { user.update_attributes(valid_cc_attributes.merge(:cc_expire_on => 1.year.from_now)) }

        specify { user.cc_expire_on.should == 1.year.from_now.end_of_month.to_date }
        specify { user.should_not be_credit_card_expired }
      end

      context "with a credit card not expired (bis)" do
        before(:each) { user.update_attributes(valid_cc_attributes.merge(:cc_expire_on => 1.month.from_now)) }

        specify { user.cc_expire_on.should == 1.month.from_now.end_of_month.to_date }
        specify { user.should_not be_credit_card_expired }
      end

      context "with a credit card expired" do
        before(:each) { user.update_attributes(valid_cc_attributes.merge(:cc_expire_on => 1.month.ago)) }

        specify { user.cc_expire_on.should == 1.month.ago.end_of_month.to_date }
        specify { user.should be_credit_card_expired }
      end
    end

    describe "#keep_some_credit_card_info" do
      before(:each) do
        user.update_attributes(valid_cc_attributes)
        user.keep_some_credit_card_info
      end
      subject { user }

      its(:cc_type)        { should == "visa" }
      its(:cc_last_digits) { should == "1111" }
      its(:cc_expire_on)   { should be_present }
    end

    describe "#check_credit_card" do
      context "valid authorization" do
        use_vcr_cassette "ogone/void_authorization"
        before(:each) { user.attributes = valid_cc_attributes }
        subject { user }

        it "should actually call Ogone and return a hash with infos" do
          Ogone.should_receive(:authorize).with(100, an_instance_of(ActiveMerchant::Billing::CreditCard), an_instance_of(Hash)) { mock('authorize', :params => {}, :authorization => '123')}
          subject.check_credit_card
        end

        it "should return a hash with infos" do
          subject.check_credit_card.should == "authorized"
        end
      end

      context "3d secure authorization" do
        use_vcr_cassette "ogone/3ds_authorization"
        before(:each) { user.update_attributes(valid_cc_d3d_attributes) }
        subject { user }

        it "should return the HTML_ANSWER returned by Ogone" do
          subject.check_credit_card.should == "d3d"
          subject.d3d_html.should be_an_instance_of(String)
        end
      end

      context "refused authorization" do
        use_vcr_cassette "ogone/refused_authorization"
        before(:each) { user.update_attributes(invalid_cc_attributes) }
        subject { user }

        it "should return nil" do
          subject.check_credit_card.should == "refused"
        end
      end
    end

    describe "#process_cc_authorization_response" do
      before(:each) { user.update_attributes(valid_cc_attributes) }
      subject { user }

      context "Authorized (status == 5)" do
        before(:each) { subject.should_receive(:void_authorization).with("1234;RES") }
        let(:params) { [{ "STATUS" => "5" }, "1234;RES"]}

        it "should return a hash with infos" do
          subject.process_cc_authorization_response(*params).should == "authorized"
        end

        it "should not add an error on base to the user" do
          subject.process_cc_authorization_response(*params)
          subject.errors.should be_empty
        end
      end

      context "Waiting for identification (status == 46)" do
        let(:params) { [{ "STATUS" => "46", "HTML_ANSWER" => Base64.encode64("<html>No HTML.</html>") }, "1234;RES"] }

        it "should return the html to inject" do
          subject.process_cc_authorization_response(*params).should == "d3d"
        end
      end

      context "Authorization invalid or incomplete (status == 0)" do
        let(:params) { [{ "STATUS" => "0" }, "1234;RES"] }

        it "should return a hash with infos" do
          subject.process_cc_authorization_response(*params).should == "invalid"
        end

        it "should add an error on base to the user" do
          subject.process_cc_authorization_response(*params)
          subject.errors[:base].should == ["Credit card information invalid or incomplete, please retry."]
        end
      end

      context "Authorization refused (status == 2)" do
        let(:params) { [{ "STATUS" => "2" }, "1234;RES"] }

        it "should return a hash with infos" do
          subject.process_cc_authorization_response(*params).should == "refused"
        end

        it "should add an error on base to the user" do
          subject.process_cc_authorization_response(*params)
          subject.errors[:base].should == ["Credit card authorization refused, please retry."]
        end
      end

      context "Authorization waiting (status == 51)" do
        let(:params) { [{ "STATUS" => "51" }, "1234;RES"] }

        it "should return a hash with infos" do
          subject.process_cc_authorization_response(*params).should == "waiting"
        end

        it "should not add an error on base to the user" do
          subject.process_cc_authorization_response(*params)
          subject.errors.should be_empty
        end
      end

      context "Authorization not known (status == 52)" do
        let(:params) { [{ "STATUS" => "52" }, "1234;RES"] }

        it "should return a hash with infos" do
          subject.process_cc_authorization_response(*params).should == "unknown"
        end

        it "should not add an error on base to the user" do
          subject.process_cc_authorization_response(*params)
          subject.errors.should be_empty
        end
      end
    end

    describe "#credit_card" do
      context "when attributes are present" do
        before(:each) { user.attributes = valid_cc_attributes }
        subject { user }

        it "should return a ActiveMerchant::Billing::CreditCard instance" do
          subject.credit_card.should be_an_instance_of(ActiveMerchant::Billing::CreditCard)
        end
      end

      context "when attributes are not present" do
        before(:each) { user.attributes = nil_cc_attributes }
        subject { user }

        it "should return a ActiveMerchant::Billing::CreditCard instance" do
          subject.credit_card.should be_nil
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
