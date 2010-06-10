require 'spec_helper'

describe Ogone do
  
  context "with visa credit card" do
    before(:each) do
      @cc = ActiveMerchant::Billing::CreditCard.new(
        :type               => 'visa',
        :number             => '4111111111111111',
        :month              => 10,
        :year               => Date.today.year + 1,
        :first_name         => 'John',
        :last_name          => 'Doe',
        :verification_value => '111'
      )
    end
    
    describe "payement of $10" do
      before(:each) { VCR.insert_cassette('ogone_visa_payement_10') }
      
      subject { Ogone.purchase(1000, @cc, :currency => 'USD') }
      
      it { should be_success }
      its(:message) { should == "The transaction was successful" }
      
      after(:each) { VCR.eject_cassette }
    end
    
    describe "authorize of $1 with alias" do
      before(:each) { VCR.insert_cassette('ogone_visa_authorize_1') }
      
      subject { Ogone.authorize(100, @cc, :currency => 'USD', :store => 'sublime_33') }
      
      it { should be_success }
      its(:message) { should == "The transaction was successful" }
      
      it "should be able to be deleted" do
        response = Ogone.void(subject.authorization)
        response.should be_success
        response.message.should == 'The transaction was successful'
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    describe "payement of $2000 via alias" do
      before(:each) { VCR.insert_cassette('ogone_visa_payement_2000_alias') }
      
      subject { Ogone.authorize(2000, 'sublime_33', :currency => 'USD') }
      
      it { should be_success }
      its(:message) { should == "The transaction was successful" }
      
      after(:each) { VCR.eject_cassette }
    end
    
    describe "payement of $9999" do
      before(:each) { VCR.insert_cassette('ogone_visa_payement_9999') }
      
      subject { Ogone.purchase(999900, @cc, :currency => 'USD') }
      
      it { should_not be_success }
      its(:message) { should == "We received an unknown status for the transaction. we will contact your acquirer and update the status of the transaction within one working day. please check the status later." }
      
      after(:each) { VCR.eject_cassette }
    end
    
    describe "payement of $10000" do
      before(:each) { VCR.insert_cassette('ogone_visa_payement_10000') }
      
      subject { Ogone.purchase(1000000, @cc, :currency => 'USD') }
      
      it { should_not be_success }
      its(:message) { should == "Card refused" }
      
      after(:each) { VCR.eject_cassette }
    end
    
  end
  
  context "with mastercard credit card" do
    before(:each) do
      @cc = ActiveMerchant::Billing::CreditCard.new(
        :type               => 'mastercard',
        :number             => '5399999999999999',
        :month              => 10,
        :year               => Date.today.year + 1,
        :first_name         => 'John',
        :last_name          => 'Doe',
        :verification_value => '111'
      )
    end
    
    describe "payement of $100" do
      before(:each) { VCR.insert_cassette('ogone_mastercard_100') }
      
      subject { Ogone.purchase(10000, @cc, :currency => 'USD') }
      
      it { should be_success }
      its(:message)       { should == "The transaction was successful" }
      
      after(:each) { VCR.eject_cassette }
    end
    
  end
  
end