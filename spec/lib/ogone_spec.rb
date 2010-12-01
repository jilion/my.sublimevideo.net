# coding: utf-8
require 'spec_helper'

describe Ogone do
  
  context "with visa credit card" do
    before(:all) do
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
    
    describe ".authorize" do
      describe "authorize of $1 with alias" do
        use_vcr_cassette "ogone_visa_authorize_1_alias"
        subject { Ogone.authorize(100, @cc, :currency => 'USD', :store => 'sublime_33') }
        
        it { should be_success }
        its(:message) { should == "The transaction was successful" }
        
        it "should be able to be deleted" do
          response = Ogone.void(subject.authorization)
          response.should be_success
          response.message.should == 'The transaction was successful'
        end
      end
    end
    
    describe ".purchase" do
      describe "payment of $10" do
        use_vcr_cassette "ogone_visa_payment_10"
        subject { Ogone.purchase(1000, @cc, :currency => 'USD') }
        
        it { should be_success }
        its(:message) { should == "The transaction was successful" }
      end
      
      describe "payment of $20 via alias" do
        use_vcr_cassette "ogone_visa_payment_2000_alias"
        subject { Ogone.purchase(2000, 'sublime_33', :currency => 'USD') }
        
        it { should be_success }
        its(:message) { should == "The transaction was successful" }
      end
      
      describe "payment of $9999" do
        use_vcr_cassette "ogone_visa_payment_9999"
        subject { Ogone.purchase(999900, @cc, :currency => 'USD') }
        
        it { should_not be_success }
        its(:message) { should == "We received an unknown status for the transaction. we will contact your acquirer and update the status of the transaction within one working day. please check the status later." }
      end
      
      describe "payment of €20" do
        use_vcr_cassette "ogone_visa_payment_20_euros"
        subject { Ogone.purchase(2000, @cc, :currency => 'EUR') }
        
        it { should_not be_success }
        its(:message) { should == "The currency is not accepted by the merchant:eur" }
      end
      
      describe "payment of $10000" do
        use_vcr_cassette "ogone_visa_payment_10000"
        subject { Ogone.purchase(1000000, @cc, :currency => 'USD') }
        
        it { should_not be_success }
        its(:message) { should == "Card refused" }
      end
    end
  end
  
  context "with master credit card" do
    before(:all) do
      @cc = ActiveMerchant::Billing::CreditCard.new(
        :type               => 'master',
        :number             => '5399999999999999',
        :month              => 10,
        :year               => Date.today.year + 1,
        :first_name         => 'John',
        :last_name          => 'Doe',
        :verification_value => '111'
      )
    end
    
    describe ".purchase" do
      describe "payment of $100" do
        use_vcr_cassette "ogone_master_100"
        subject { Ogone.purchase(10000, @cc, :currency => 'USD') }
        
        it { should be_success }
        its(:message) { should == "The transaction was successful" }
      end
    end
  end
  
end