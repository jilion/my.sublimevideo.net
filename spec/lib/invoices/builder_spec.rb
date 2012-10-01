require 'fast_spec_helper'
require File.expand_path('lib/invoices/builder')


describe Invoices::Builder do
  unless defined? Invoice
    class Invoice
      attr_accessor :site, :invoice_items, :invoice_items_amount, :vat_rate, :vat_amount, :balance_deduction_amount, :amount
      def initialize(attributes = {})
        @attributes = attributes
        @invoice_items = @attributes[:invoice_items] || []
      end
      def site
        @attributes[:site]
      end
    end
    after(:all) { Object.send(:remove_const, :Invoice) }
  end

  let(:invoice_item1) { stub(:invoice_item, amount: 1000) }
  let(:invoice_item2) { stub(:invoice_item, amount: 2000) }
  let(:user) { stub(billing_country: 'FR', balance: 0) }
  let(:attributes) { { site: stub(user: user), invoice_items: [invoice_item1, invoice_item2] } }
  let(:builder) { described_class.new(attributes) }

  describe '#initialize' do
    it 'pass the parameters to Invoice.new' do
      Invoice.should_receive(:new).with(attributes)

      builder
    end
  end

  describe '#invoice' do
    it 'gives access to its invoice' do
      builder.invoice.should be_a Invoice
    end
  end

  describe '#add_invoice_item' do
    let(:builder) { described_class.new }

    it 'add given invoice item' do
      builder.add_invoice_item(invoice_item1)
      builder.invoice.invoice_items.should eq [invoice_item1]

      builder.add_invoice_item(invoice_item2)
      builder.invoice.invoice_items.should eq [invoice_item1, invoice_item2]
    end
  end

  describe '#save' do
    context 'invoice is valid' do
      before do
        builder.invoice.should_receive(:valid?) { true }
        builder.invoice.should_receive(:save) { true }

        builder.save
      end

      context 'non-swiss user' do
        it 'calls #save on the invoice' do
          builder.invoice.invoice_items_amount.should eq 3000
          builder.invoice.vat_rate.should eq 0
          builder.invoice.vat_amount.should eq 0
          builder.invoice.balance_deduction_amount.should eq 0
          builder.invoice.amount.should eq 3000
        end
      end

      context 'swiss user' do
        let(:user) { stub(billing_country: 'CH', balance: 0) }

        it 'calls #save on the invoice' do
          builder.invoice.invoice_items_amount.should eq 3000
          builder.invoice.vat_rate.should eq 0.08
          builder.invoice.vat_amount.should eq 3000 * 0.08
          builder.invoice.balance_deduction_amount.should eq 0
          builder.invoice.amount.should eq 3000 + 3000 * 0.08
        end
      end

      context 'user with a balance' do
        let(:user) { stub(billing_country: 'FR', balance: 1000) }

        it 'calls #save on the invoice' do
          builder.invoice.invoice_items_amount.should eq 3000
          builder.invoice.vat_rate.should eq 0
          builder.invoice.vat_amount.should eq 0
          builder.invoice.balance_deduction_amount.should eq 1000
          builder.invoice.amount.should eq 3000 - 1000
        end
      end

    end
  end

end
