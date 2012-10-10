require 'spec_helper'
require File.expand_path('lib/service/invoice')

describe Service::Invoice do
  let(:user) { create(:user, billing_country: 'FR', balance: 0) }
  let(:site) { create(:site, user: user) }
  let(:plus_plan) { create(:plan, name: 'plus', price: 990) }
  let(:hidden_addon_plan_free) { create(:addon_plan, availability: 'hidden', price: 0) }
  let(:hidden_addon_plan_paid) { create(:addon_plan, availability: 'hidden', price: 995) }
  let(:public_addon_plan_free) { create(:addon_plan, availability: 'public', price: 0) }
  let(:public_addon_plan_paid) { create(:addon_plan, availability: 'public', price: 995) }
  let(:custom_addon_plan_free) { create(:addon_plan, availability: 'custom', price: 0) }
  let(:custom_addon_plan_paid) { create(:addon_plan, availability: 'custom', price: 995) }
  let(:service) { described_class.build_for_month(1.month.ago.beginning_of_month, site: site) }

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
        invoice = described_class.build_for_month(1.month.ago.beginning_of_month, site: site).invoice

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
          invoice = described_class.build_for_month(4.months.ago, site: site).invoice
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
          invoice = described_class.build_for_month(2.months.ago, site: site).invoice
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
          invoice = described_class.build_for_month(2.months.ago, site: site).invoice
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
          invoice = described_class.build_for_month(1.month.ago, site: site).invoice
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
          invoice = described_class.build_for_month(2.months.ago, site: site).invoice
          invoice.invoice_items.should be_empty
        end
      end

      context 'for 1 month ago' do
        it 'creates 1 period, starting on the 15th day and ending at the end of the month' do
          invoice = described_class.build_for_month(1.month.ago, site: site).invoice
          invoice.invoice_items.should have(1).item

          invoice.invoice_items[0].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 1.month.ago.beginning_of_month + 15.days
          invoice.invoice_items[0].ended_at.should eq 1.month.ago.end_of_month
          invoice.invoice_items[0].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(1.month.ago)) * (days_in_month(1.month.ago) - 15)).round
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
          invoice = described_class.build_for_month(1.month.ago, site: site).invoice
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
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month + 15.days)
        create(:billable_item_activity, site: site, item: plus_plan, state: 'subscribed', created_at: 2.months.ago.beginning_of_month)
        create(:billable_item_activity, site: site, item: plus_plan, state: 'suspended', created_at: 1.month.ago.beginning_of_month + 10.days)
      end

      context 'for 1 month ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(1.month.ago, site: site).invoice
          invoice.invoice_items.should have(2).item

          invoice.invoice_items[0].item.should eq plus_plan
          invoice.invoice_items[1].item.should eq plus_plan

          invoice.invoice_items[0].started_at.should eq 1.month.ago.beginning_of_month
          invoice.invoice_items[0].ended_at.should eq 1.month.ago.beginning_of_month + 10.days
          invoice.invoice_items[0].amount.should eq ((plus_plan.price.to_f / days_in_month(1.month.ago)) * 10).round

          invoice.invoice_items[1].started_at.should eq 1.month.ago.beginning_of_month + 15.days
          invoice.invoice_items[1].ended_at.should eq 1.month.ago.end_of_month
          invoice.invoice_items[1].price.should eq plus_plan.price
          invoice.invoice_items[1].amount.should eq ((plus_plan.price.to_f / days_in_month(1.month.ago)) * (days_in_month(1.month.ago) - 15)).round
        end
      end
    end

    describe 'full example' do
      before do
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'beta', created_at: 6.months.ago.beginning_of_month + 2.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'trial', created_at: 5.months.ago.beginning_of_month + 5.days)
        create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 4.months.ago.beginning_of_month + 5.days)
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
          invoice = described_class.build_for_month(6.month.ago, site: site).invoice
          invoice.invoice_items.should be_empty
        end
      end

      context 'for 5 months ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(5.month.ago, site: site).invoice
          invoice.invoice_items.should be_empty
        end
      end

      context 'for 4 month ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(4.month.ago, site: site).invoice
          invoice.invoice_items.should have(2).item

          invoice.invoice_items[0].item.should eq custom_addon_plan_paid
          invoice.invoice_items[1].item.should eq public_addon_plan_paid

          invoice.invoice_items[0].started_at.should eq 4.month.ago.beginning_of_month + 3.days
          invoice.invoice_items[0].ended_at.should eq 4.month.ago.end_of_month
          invoice.invoice_items[0].price.should eq custom_addon_plan_paid.price
          invoice.invoice_items[0].amount.should eq ((custom_addon_plan_paid.price.to_f / days_in_month(4.month.ago)) * (days_in_month(4.month.ago) - 3)).round

          invoice.invoice_items[1].started_at.should eq 4.month.ago.beginning_of_month + 5.days
          invoice.invoice_items[1].ended_at.should eq 4.month.ago.beginning_of_month + 10.days
          invoice.invoice_items[1].price.should eq public_addon_plan_paid.price
          invoice.invoice_items[1].amount.should eq ((public_addon_plan_paid.price.to_f / days_in_month(4.month.ago)) * 5).round
        end
      end

      context 'for 3 month ago' do
        it 'creates 1 period, starting at the beginning of the month and ending on the 15th day' do
          invoice = described_class.build_for_month(3.month.ago, site: site).invoice
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
          invoice = described_class.build_for_month(2.month.ago, site: site).invoice
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
          invoice = described_class.build_for_month(1.month.ago, site: site).invoice
          invoice.invoice_items.should be_empty
        end
      end
    end
  end

  describe '#save' do
    before do
      create(:billable_item_activity, site: site, item: public_addon_plan_paid, state: 'subscribed', created_at: 1.month.ago.beginning_of_month)
    end

    context 'non-swiss user' do
      it 'has no VAT' do
        service.save

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
        service.save

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
        service.save

        service.invoice.invoice_items_amount.should eq 995
        service.invoice.vat_rate.should eq 0
        service.invoice.vat_amount.should eq 0
        service.invoice.balance_deduction_amount.should eq 500
        service.invoice.amount.should eq 995 - 500
      end
    end

    it 'saves the invoice' do
      service.invoice.should be_new_record
      service.save
      service.invoice.should be_persisted
    end
  end

  describe '#full_days' do
    it { described_class.send(:full_days, Time.now.utc.midnight, Time.now.utc.end_of_day - 1).should eq 0 }
    it { described_class.send(:full_days, Time.now.utc.midnight, Time.now.utc.end_of_day).should eq 1 }
    it { described_class.send(:full_days, Time.now.utc.midnight, Time.now.utc.end_of_day + 1).should eq 1 }
    it { described_class.send(:full_days, Time.now.utc.midnight, Time.now.utc.tomorrow).should eq 1 }
  end

end

def days_in_month(date)
  Time.days_in_month(date.month, date.year)
end
