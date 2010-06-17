# == Schema Information
#
# Table name: users
#
#  cc_type                               :string(255)
#  cc_last_digits                        :integer
#  cc_expire_on                         :date
#  cc_updated_at                         :datetime
#

require 'spec_helper'

describe User::CreditCard do
  let(:user) { Factory(:user) }
  
  describe "with valid attributes" do
    before(:each) do
      VCR.insert_cassette('credit_card_visa_validation')
      user.update_attributes(valid_attributes)
    end
    subject { user }
    
    it { should be_valid }
    it { should be_credit_card }
    it { should be_cc }
    its(:cc_type)         { should == 'visa' }
    its(:cc_last_digits)  { should == 1111 }
    its(:cc_expire_on)   { should == 1.year.from_now.to_date }
    its(:cc_updated_at)   { should be_present }
    
    it "should void authorization after verification" do
      mock_response = mock('response', :success? => true)
      Ogone.should_receive(:void).and_return(mock_response)
      user.save
    end
    
    it "should notify if void authorization after verification failed" do
      mock_response = mock('response', :success? => false, :message => 'failed')
      Ogone.stub(:void).and_return(mock_response)
      HoptoadNotifier.should_receive(:notify)
      user.save
    end
    
    after(:each) { VCR.eject_cassette }
  end
  
  describe "cc_type" do
    it "should take cc_type from cc_number if nil" do
      VCR.use_cassette('credit_card_visa_validation') do
        user.update_attributes(valid_attributes.merge(:cc_type => nil))
        user.cc_type.should == 'visa'
      end
    end
  end
  
  describe "validations" do
    it "should validates cc_type" do
      user.attributes = valid_attributes.merge(:cc_type => 'master')
      user.should_not be_valid
      user.errors[:cc_type].should be_present
    end
    it "should validates cc_type if not matching cc_number" do
      user.attributes = valid_attributes.merge(:cc_number => '5399999999999999')
      user.should_not be_valid
      user.errors[:cc_type].should be_present
    end
    it "should validates cc_type if matching cc_number" do
      VCR.use_cassette('credit_card_master_validation') do
        user.attributes = valid_attributes.merge(:cc_number => '5399999999999999', :cc_type => 'master')
        user.should be_valid
      end
    end
    it "should validates cc_number presence" do
      user.attributes = valid_attributes.merge(:cc_number => nil)
      user.should_not be_valid
      user.errors[:cc_number].should be_present
    end
    it "should validates cc_number" do
      user.attributes = valid_attributes.merge(:cc_number => '33')
      user.should_not be_valid
      user.errors[:cc_number].should be_present
    end
    it "should validates cc_expire_on" do
      user.attributes = valid_attributes.merge(:cc_expire_on => 50.years.ago)
      user.should_not be_valid
      user.errors[:cc_expire_on].should be_present
    end
    it "should validates cc_first_name presence" do
      user.attributes = valid_attributes.merge(:cc_first_name => nil)
      user.should_not be_valid
      user.errors[:cc_first_name].should be_present
    end
    it "should validates cc_last_name presence" do
      user.attributes = valid_attributes.merge(:cc_last_name => nil)
      user.should_not be_valid
      user.errors[:cc_last_name].should be_present
    end
    it "should validates cc_verification_value presence" do
      user.attributes = valid_attributes.merge(:cc_verification_value => nil)
      user.should_not be_valid
      user.errors[:cc_verification_value].should be_present
    end
    
    it "should add error on base if authorization failed" do
      VCR.use_cassette('credit_card_visa_invalid_authorization') do
        user.attributes = valid_attributes.merge(:cc_number => '4111113333333333')
        user.save.should be_false
        user.errors[:base].should be_present
      end
    end
  end
  
end

def valid_attributes
  {
    :cc_type               => 'visa',
    :cc_number             => '4111111111111111',
    :cc_expire_on         => 1.year.from_now.to_date,
    :cc_first_name         => 'John',
    :cc_last_name          => 'Doe',
    :cc_verification_value => '111'
  }
end