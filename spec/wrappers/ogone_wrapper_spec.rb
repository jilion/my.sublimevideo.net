# coding: utf-8
require 'fast_spec_helper'
require 'config/vcr'

require 'wrappers/ogone_wrapper'

describe OgoneWrapper do

  context 'with visa credit card' do
    let(:cc) {
      ActiveMerchant::Billing::CreditCard.new(
        brand:              'visa',
        number:             '4111111111111111',
        month:              10,
        year:               Date.today.year + 1,
        first_name:         'John',
        last_name:          'Doe',
        verification_value: '111'
      )
    }

    describe '.store' do
      describe 'store of $0.01 with alias' do
        use_vcr_cassette 'ogone/visa_authorize_1_alias'
        subject { described_class.store(cc, currency: 'USD', billing_id: 'sublime_33') }

        it { should be_success }
        its(:message) { should eq 'The transaction was successful' }
      end
    end

    describe '.purchase' do
      describe 'payment of $10' do
        use_vcr_cassette 'ogone/visa_payment_generic'
        subject { described_class.purchase(1000, cc, currency: 'USD') }

        it { should be_success }
        its(:message) { should eq 'The transaction was successful' }
      end

      describe 'payment of $20 via alias' do
        use_vcr_cassette 'ogone/visa_payment_2000_alias'
        subject { described_class.purchase(2000, 'sublime_33', currency: 'USD') }

        it { should be_success }
        its(:message) { should eq 'The transaction was successful' }
      end

      describe 'payment of $9999' do
        use_vcr_cassette 'ogone/visa_payment_9999'
        subject { described_class.purchase(999900, cc, currency: 'USD') }

        it { should_not be_success }
        its(:message) { should eq 'We received an unknown status for the transaction. we will contact your acquirer and update the status of the transaction within one working day. please check the status later.' }
      end

      describe 'payment of €20' do
        use_vcr_cassette 'ogone/visa_payment_20_euros'
        subject { described_class.purchase(2000, cc, currency: 'EUR') }

        it { should_not be_success }
        its(:message) { should eq 'The currency is not accepted by the merchant:eur' }
      end

      describe 'payment of $10000' do
        use_vcr_cassette 'ogone/visa_payment_10000'
        subject { described_class.purchase(1000000, cc, currency: 'USD') }

        it { should_not be_success }
        its(:message) { should eq 'Card refused' }
      end
    end

    describe '.refund' do
      describe 'refund of $10 via a transaction pay_id that succeeds' do
        before do
          VCR.use_cassette 'ogone/visa_payment_generic' do
            @purchase = described_class.purchase(1000, cc, currency: 'USD')
          end
        end
        subject { described_class.refund(1000, @purchase.authorization) }

        it { VCR.use_cassette('ogone/visa_refund_generic') { subject.should be_success } }
      end

      describe 'refund of $10 via a transaction pay_id that fails' do
        before do
          VCR.use_cassette 'ogone/visa_payment_generic' do
            @purchase = described_class.purchase(1000, cc, currency: 'USD')
          end
        end
        subject { described_class.refund(3000, @purchase.authorization) } # amount bigger than the original sale

        it { VCR.use_cassette('ogone/visa_refund_failed') { subject.should_not be_success } }
      end
    end
  end

  context 'with master credit card' do
    let(:cc) {
      ActiveMerchant::Billing::CreditCard.new(
        brand:              'master',
        number:             '5399999999999999',
        month:              10,
        year:               Date.today.year + 1,
        first_name:         'John',
        last_name:          'Doe',
        verification_value: '111'
      )
    }

    describe '.purchase' do
      describe 'payment of $100' do
        use_vcr_cassette 'ogone/master_100'
        subject { described_class.purchase(10000, cc, currency: 'USD') }

        it { should be_success }
        its(:message) { should eq 'The transaction was successful' }
      end
    end
  end

  context 'with american_express credit card' do
    let(:cc) {
      ActiveMerchant::Billing::CreditCard.new(
        brand:              'american_express',
        number:             '374111111111111',
        month:              10,
        year:               Date.today.year + 1,
        first_name:         'John',
        last_name:          'Doe',
        verification_value: '1111'
      )
    }

    describe '.purchase' do
      describe 'payment of $100' do
        use_vcr_cassette 'ogone/american_express_100'
        subject { described_class.purchase(10000, cc, currency: 'USD') }

        it { should be_success }
        its(:message) { should eq 'The transaction was successful' }
      end
    end
  end

end
