require 'spec_helper'

describe InvoiceCreator do
  let(:user) { create(:user, billing_country: 'FR', balance: 0) }
  let(:site) { create(:site, user: user) }
  let(:site2) { create(:site, user: user) }
  let(:site3) { create(:site, user: user) }
  let(:site4) { create(:site, user: user) }
  let(:site5) { create(:site, user: user) }
  let(:hidden_addon_plan_free) { create(:addon_plan, availability: 'hidden', price: 0) }
  let(:hidden_addon_plan_paid) { create(:addon_plan, availability: 'hidden', price: 995) }
  let(:public_addon_plan_free) { create(:addon_plan, availability: 'public', price: 0) }
  let(:public_addon_plan_paid) { create(:addon_plan, availability: 'public', price: 995) }
  let(:custom_addon_plan_free) { create(:addon_plan, availability: 'custom', price: 0) }
  let(:custom_addon_plan_paid) { create(:addon_plan, availability: 'custom', price: 995) }
  let(:service) { described_class.build_for_month(1.month.ago, site) }
  before { Timecop.travel(Time.utc(2013, 3)) }
  after { Timecop.return }

  describe '.create_invoices_for_month' do
    before do
      create(:billable_item, site: site, item: public_addon_plan_paid, state: 'beta')
      create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'beta', created_at: 1.months.ago.beginning_of_month)
      create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'trial', created_at: 1.months.ago.beginning_of_month + 2.days)
      create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.months.ago.beginning_of_month + 5.days)
      create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'canceled', created_at: 1.month.ago.beginning_of_month + 10.days)

      create(:billable_item, site: site2, item: public_addon_plan_paid, state: 'trial')
      create(:billable_item_activity, site: site2, item: public_addon_plan_paid, state: 'trial', created_at: 1.months.ago.beginning_of_month)

      create(:billable_item, site: site3, item: public_addon_plan_paid, state: 'subscribed')
      create(:billable_item_activity, site: site3, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.months.ago.beginning_of_month)
      Sidekiq::Worker.clear_all
    end

    it 'delay invoices creation for all paying sites for the given date' do
      described_class.create_invoices_for_month(3.months.ago)

      expect { Sidekiq::Worker.drain_all }.to_not change(Invoice, :count)
    end

    it 'delay invoices creation for all paying sites for the last month' do
      described_class.create_invoices_for_month

      expect { Sidekiq::Worker.drain_all }.to change(Invoice, :count).by(2)
    end
  end

  describe '.build_for_month' do
    describe 'billable items filtering' do
      before do
        create(:billable_item_activity, site: site, item: hidden_addon_plan_free, state: 'subscribed', created_at: 1.month.ago.beginning_of_month)
        create(:billable_item_activity, site: site, item: hidden_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 1)
        create(:billable_item_activity, site: site, item: public_addon_plan_free, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 2)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 3)
        create(:billable_item_activity, site: site, item: custom_addon_plan_free, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 4)
        create(:billable_item_activity, site: site, item: custom_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 5)
      end

      it 'takes in account only billable items with a price > 0' do
        invoice = described_class.build_for_month(1.month.ago, site).invoice

        invoice.invoice_items.should have(3).items

        invoice.invoice_items[0].item.should eq hidden_addon_plan_paid
        invoice.invoice_items[1].item.should eq public_addon_plan_paid
        invoice.invoice_items[2].item.should eq custom_addon_plan_paid
      end
    end

    describe 'billable items that is subscribed since long time ago' do
      before do
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 5.months.ago)
      end

      context 'for 4 months ago' do
        it 'creates 1 period that last the whole month' do
          invoice = described_class.build_for_month(4.months.ago, site).invoice
          invoice.invoice_items.should have(1).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 4.months.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 4.months.ago.end_of_month
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq public_addon_plan_paid.price
        end
      end

      context 'for 2 months ago' do
        it 'creates 1 period that last the whole month' do
          invoice = described_class.build_for_month(2.months.ago, site).invoice
          invoice.invoice_items.should have(1).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 2.months.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 2.months.ago.end_of_month
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq public_addon_plan_paid.price
        end
      end
    end

    describe 'billable items with multiple periods [subscribed, canceled], started during the last month' do
      before do
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 2.months.ago.beginning_of_month + 15.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'canceled', created_at: 1.month.ago.beginning_of_month + 5.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 10.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'canceled', created_at: Time.now.utc)
      end

      context 'for 2 months ago' do
        it 'creates 1 period that last the whole month' do
          invoice = described_class.build_for_month(2.months.ago, site).invoice
          invoice.invoice_items.should have(1).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 2.months.ago.beginning_of_month + 15.days
          invoice.invoice_items[0].ended_at.should eq 2.months.ago.end_of_month
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(2.months.ago)) * (days_in_month(2.months.ago) - 15)).round
        end
      end

      context 'for 1 month ago' do
        it 'creates 2 periods, with the second one starting on the 10th day and ending at the end of the month' do
          invoice = described_class.build_for_month(1.month.ago, site).invoice
          invoice.invoice_items.should have(2).items

          invoice.invoice_items[0].item.should eq public_addon_plan_paid
          invoice.invoice_items[1].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 1.month.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 1.month.ago.beginning_of_month + 5.days
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(1.month.ago)) * 5).round

          invoice.invoice_items[1].started_at.should eq 1.month.ago.beginning_of_month + 10.days
          invoice.invoice_items[1].ended_at.should eq 1.month.ago.end_of_month
          invoice.invoice_items[1].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[1].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(1.month.ago)) * (days_in_month(1.month.ago) - 10)).round
        end
      end
    end

    describe 'billable item with multiple periods [beta, trial, subscribed], started during the last month' do
      before do
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'beta', created_at: 2.months.ago.beginning_of_month)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'canceled', created_at: 2.months.ago.beginning_of_month + 5.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'trial', created_at: 1.month.ago.beginning_of_month + 5.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'canceled', created_at: 1.month.ago.beginning_of_month + 7.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'trial', created_at: 1.month.ago.beginning_of_month + 9.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'canceled', created_at: 1.month.ago.beginning_of_month + 12.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 15.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'canceled', created_at: Time.now.utc)
      end

      context 'for 2 months ago' do
        it 'doesnt create any invoice items' do
          invoice = described_class.build_for_month(2.months.ago, site).invoice
          invoice.invoice_items.should be_empty
        end
      end

      context 'for 1 month ago' do
        it 'creates 1 period, starting on the 15th day and ending at the end of the month' do
          invoice = described_class.build_for_month(1.month.ago, site).invoice
          invoice.invoice_items.should have(1).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 1.month.ago.beginning_of_month + 15.days
          invoice.invoice_items[0].ended_at.should eq 1.month.ago.end_of_month
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(1.month.ago)) * (days_in_month(1.month.ago) - 15)).round
        end
      end
    end

    describe 'billable item with wrong items sequences (but happened in production so we must handle this) periods [subscribed, trial, subscribed], started during the last month' do
      before do
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 2.month.ago.beginning_of_month + 5.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'trial', created_at: 2.month.ago.beginning_of_month + 9.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 15.days)
      end

      context 'for 1 month ago' do
        it 'creates 1 period, starting on the 5th day and ending at the end of the month' do
          invoice = described_class.build_for_month(1.month.ago, site).invoice
          invoice.invoice_items.should have(1).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 1.month.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 1.month.ago.end_of_month
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq public_addon_plan_paid.price
        end
      end
    end

    describe 'billable item sponsored during the last month' do
      before do
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 2.months.ago.beginning_of_month)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'sponsored', created_at: 1.month.ago.beginning_of_month + 15.days)
      end

      context 'for 1 month ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(1.month.ago, site).invoice
          invoice.invoice_items.should have(1).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 1.month.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 1.month.ago.beginning_of_month + 15.days
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(1.month.ago)) * 15).round
        end
      end
    end

    describe 'billable item suspended and then subscribed during the last month' do
      before do
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 2.months.ago.beginning_of_month)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'suspended', created_at: 1.month.ago.beginning_of_month + 10.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 15.days)
      end

      context 'for 1 month ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(1.month.ago, site).invoice
          invoice.invoice_items.should have(2).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid
          invoice.invoice_items[1].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 1.month.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 1.month.ago.beginning_of_month + 10.days
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(1.month.ago)) * 10).round

          invoice.invoice_items[1].started_at.should eq 1.month.ago.beginning_of_month + 15.days
          invoice.invoice_items[1].ended_at.should eq 1.month.ago.end_of_month
          invoice.invoice_items[1].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[1].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(1.month.ago)) * (days_in_month(1.month.ago) - 15)).round
        end
      end
    end

    describe 'full example' do
      before do
        create(:invoice, site: site) # first invoice

        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 6.months.ago.beginning_of_month + 2.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'trial', created_at: 6.months.ago.beginning_of_month + 5.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 5.months.ago.beginning_of_month + 5.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'canceled', created_at: 4.month.ago.beginning_of_month + 10.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 3.months.ago.beginning_of_month + 2.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'suspended', created_at: 2.month.ago.beginning_of_month + 10.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'sponsored', created_at: 1.month.ago.beginning_of_month + 15.days)

        create(:billable_item_activity, site: site, item: custom_addon_plan_paid, state: 'beta', created_at: 6.months.ago.beginning_of_month + 2.days)
        create(:billable_item_activity, site: site, item: custom_addon_plan_paid, state: 'trial', created_at: 5.months.ago.beginning_of_month + 5.days)
        create(:billable_item_activity, site: site, item: custom_addon_plan_paid, state: 'subscribed', created_at: 4.months.ago.beginning_of_month + 3.days)
        create(:billable_item_activity, site: site, item: custom_addon_plan_paid, state: 'suspended', created_at: 3.month.ago.beginning_of_month + 10.days)
        create(:billable_item_activity, site: site, item: custom_addon_plan_paid, state: 'subscribed', created_at: 3.months.ago.beginning_of_month + 20.days)
        create(:billable_item_activity, site: site, item: custom_addon_plan_paid, state: 'canceled', created_at: 2.month.ago.beginning_of_month + 10.days)
        create(:billable_item_activity, site: site, item: custom_addon_plan_paid, state: 'sponsored', created_at: 1.month.ago.beginning_of_month + 15.days)
      end

      context 'for 6 months ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(6.month.ago, site).invoice
          invoice.invoice_items.should have(1).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 6.month.ago.beginning_of_month + 2.days
          invoice.invoice_items[0].ended_at.should eq 6.month.ago.end_of_month
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(6.month.ago)) * (days_in_month(6.month.ago) - 2)).round
        end
      end

      context 'for 5 months ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(5.month.ago, site).invoice
          invoice.invoice_items.should have(1).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 5.month.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 5.month.ago.end_of_month
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq public_addon_plan_paid.price
        end
      end

      context 'for 4 month ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(4.month.ago, site).invoice
          invoice.invoice_items.should have(2).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid
          invoice.invoice_items[1].item.should eq custom_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 4.month.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 4.month.ago.beginning_of_month + 10.days
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(4.month.ago)) * 10).round

          invoice.invoice_items[1].started_at.should eq 4.month.ago.beginning_of_month + 3.days
          invoice.invoice_items[1].ended_at.should eq 4.month.ago.end_of_month
          invoice.invoice_items[1].price.should eq custom_addon_plan_paid.price
          invoice.invoice_items[1].amount.should eq ((custom_addon_plan_paid.price.to_f / days_in_month(4.month.ago)) * (days_in_month(4.month.ago) - 3)).round
        end
      end

      context 'for 3 month ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(3.month.ago, site).invoice
          invoice.invoice_items.should have(3).item

          invoice.invoice_items[0].item.should eq custom_addon_plan_paid
          invoice.invoice_items[1].item.should eq public_addon_plan_paid
          invoice.invoice_items[2].item.should eq custom_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 3.month.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 3.month.ago.beginning_of_month + 10.days
          invoice.invoice_items[0].price.should eq custom_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((custom_addon_plan_paid.price.to_f / days_in_month(3.month.ago)) * 10).round

          invoice.invoice_items[1].started_at.should eq 3.month.ago.beginning_of_month + 2.days
          invoice.invoice_items[1].ended_at.should eq 3.month.ago.end_of_month
          invoice.invoice_items[1].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[1].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(3.month.ago)) * (days_in_month(3.month.ago) - 2)).round

          invoice.invoice_items[2].started_at.should eq 3.month.ago.beginning_of_month + 20.days
          invoice.invoice_items[2].ended_at.should eq 3.month.ago.end_of_month
          invoice.invoice_items[2].price.should eq custom_addon_plan_paid.price
          invoice.invoice_items[2].amount.should eq ((custom_addon_plan_paid.price.to_f / days_in_month(3.month.ago)) * (days_in_month(3.month.ago) - 20)).round
        end
      end

      context 'for 2 month ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(2.month.ago, site).invoice
          invoice.invoice_items.should have(2).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid
          invoice.invoice_items[1].item.should eq custom_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 2.month.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 2.month.ago.beginning_of_month + 10.days
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(2.month.ago)) * 10).round

          invoice.invoice_items[1].started_at.should eq 2.month.ago.beginning_of_month
          invoice.invoice_items[1].ended_at.should eq 2.month.ago.beginning_of_month + 10.days
          invoice.invoice_items[1].price.should eq custom_addon_plan_paid.price
          invoice.invoice_items[1].amount.should eq ((custom_addon_plan_paid.price.to_f / days_in_month(2.month.ago)) * 10).round
        end
      end

      context 'for 1 month ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(1.month.ago, site).invoice
          invoice.invoice_items.should be_empty
        end
      end
    end
  end

  describe '#save' do
    before do
      create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month)
    end

    context 'already one canceled invoice exists for this site for this month' do
      before do
        invoice = create(:invoice, site: site, state: 'canceled')
        create(:addon_plan_invoice_item, invoice: invoice, started_at: 1.month.ago.beginning_of_month, ended_at: 1.month.ago.end_of_month)
      end

      it 'create a new invoice' do
        expect { service.save }.to change(Invoice, :count).by(1)
      end
    end

    %w[open paid].each do |state|
      context "already one #{state} invoice exists for this site for this month but started_at is before 2012, Dec 14, 15:00 UTC" do
        let(:service) { described_class.build_for_month(Time.utc(2013, 1, 1), site) }
        before do
          create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: Time.utc(2012, 12, 14, 15))
          invoice = create(:invoice, site: site, state: state)
          create(:addon_plan_invoice_item, invoice: invoice, started_at: Time.utc(2012, 12, 14, 14, 59), ended_at: Time.utc(2013, 1, 13, 14, 59))
        end

        it 'creates a new invoice' do
          expect { service.save }.to change(Invoice, :count).by(1)
        end
      end
    end

    context 'non-swiss user' do
      it 'has no VAT' do
        expect { service.save }.to change(Invoice, :count).by(1)

        service.invoice.invoice_items_amount.should eq 995
        service.invoice.vat_rate.should eq 0
        service.invoice.vat_amount.should eq 0
        service.invoice.balance_deduction_amount.should eq 0
        service.invoice.amount.should eq 995
      end
    end

    context 'swiss user' do
      let(:user) { create(:user, billing_country: 'CH', balance: 0) }

      it 'has VAT' do
        expect { service.save }.to change(Invoice, :count).by(1)

        service.invoice.invoice_items_amount.should eq 995
        service.invoice.vat_rate.should eq 0.08
        service.invoice.vat_amount.should eq (995 * 0.08).round
        service.invoice.balance_deduction_amount.should eq 0
        service.invoice.amount.should eq (995 + 995 * 0.08).round
      end
    end

    context 'user with a balance' do
      let(:user) { create(:user, billing_country: 'FR', balance: 500) }

      it 'deduct from balance' do
        expect { service.save }.to change(Invoice, :count).by(1)

        service.invoice.invoice_items_amount.should eq 995
        service.invoice.vat_rate.should eq 0
        service.invoice.vat_amount.should eq 0
        service.invoice.balance_deduction_amount.should eq 500
        service.invoice.amount.should eq 995 - 500
      end
    end

    context 'first non-canceled invoice' do
      it 'sets renew to false' do
        expect { service.save }.to change(Invoice, :count).by(1)

        service.invoice.should_not be_renew
      end
    end

    context 'not first non-canceled invoice' do
      before do
        create(:invoice, site: service.invoice.site)
      end

      it 'sets renew to true' do
        expect { service.save }.to change(Invoice, :count).by(1)

        service.invoice.should be_renew
      end
    end
  end

end

def days_in_month(date)
  Time.days_in_month(date.month, date.year)
end
