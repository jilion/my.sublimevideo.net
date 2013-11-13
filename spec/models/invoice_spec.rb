require 'spec_helper'

describe Invoice, :addons do
  let(:site) { create(:site) }

  describe "Factory" do
    subject { create(:invoice) }

    describe '#site' do
      subject { super().site }
      it                     { should be_present }
    end

    describe '#reference' do
      subject { super().reference }
      it                { should =~ /^[a-z1-9]{8}$/ }
    end

    describe '#invoice_items_amount' do
      subject { super().invoice_items_amount }
      it     { should eql 9999 }
    end

    describe '#balance_deduction_amount' do
      subject { super().balance_deduction_amount }
      it { should eql 0 }
    end

    describe '#amount' do
      subject { super().amount }
      it                   { should eql 9999 }
    end

    describe '#paid_at' do
      subject { super().paid_at }
      it                  { should be_nil }
    end

    describe '#last_failed_at' do
      subject { super().last_failed_at }
      it           { should be_nil }
    end

    it { should be_open } # initial state
    it { should be_valid }
  end # Factory

  describe "Associations" do
    subject { create(:invoice) }

    it { should belong_to :site }
    it { should have_one :user } # through :site

    it { should have_many :invoice_items }
    it { should have_and_belong_to_many :transactions }
  end # Associations

  describe "Validations" do
    subject { create(:invoice) }

    it { should validate_presence_of(:site) }
    it { should validate_presence_of(:invoice_items_amount) }
    it { should validate_presence_of(:vat_rate) }
    it { should validate_presence_of(:vat_amount) }
    it { should validate_presence_of(:balance_deduction_amount) }
    it { should validate_presence_of(:amount) }

    it { should validate_numericality_of(:invoice_items_amount) }
    it { should validate_numericality_of(:vat_rate) }
    it { should validate_numericality_of(:vat_amount) }
    it { should validate_numericality_of(:balance_deduction_amount) }
    it { should validate_numericality_of(:amount) }

    context "invoice is valid if the only one for this month" do
      before do
        @invoice = build(:invoice, site: site)
        @invoice.invoice_items << build(:addon_plan_invoice_item, started_at: 1.month.ago.beginning_of_month, ended_at: 1.month.ago.end_of_month)
        @invoice.save!
      end

      it 'can be succeeded' do
        @invoice.succeed!
      end
    end

    %w[open paid].each do |state|
      context "already one #{state} invoice exists for this site for this month" do
        before do
          old_invoice = build(:invoice, site: site, state: state)
          old_invoice.invoice_items << build(:addon_plan_invoice_item, started_at: 1.month.ago.beginning_of_month, ended_at: 1.month.ago.end_of_month)
          old_invoice.save!

          @new_invoice = build(:invoice, site: site)
          @new_invoice.invoice_items << build(:addon_plan_invoice_item, started_at: 1.month.ago.beginning_of_month, ended_at: 1.month.ago.end_of_month)
        end

        it { expect(@new_invoice).not_to be_valid }
      end
    end
  end # Validations

  describe "State Machine" do
    let(:invoice) { create(:invoice) }
    subject { invoice }

    describe "Initial state" do
      it { should be_open }
    end

    describe "Transitions" do
      describe "before_transition on: :succeed" do
        it "sets paid_at" do
          expect(invoice.paid_at).to be_nil

          invoice.succeed!

          expect(invoice.paid_at).to be_present
        end

        context "with last_failed_at present" do
          let(:failed_invoice) { create(:failed_invoice) }

          it "clears last_failed_at" do
            expect(failed_invoice.last_failed_at).to be_present

            failed_invoice.succeed!

            expect(failed_invoice.last_failed_at).to be_nil
          end
        end
      end

      describe "before_transition on: :fail" do
        it "sets last_failed_at" do
          expect(invoice.last_failed_at).to be_nil

          invoice.fail!

          expect(invoice.last_failed_at).to be_present
        end
      end

      describe "after_transition on: :succeed" do
        it "updates user.last_invoiced_amount" do
          invoice.user.update_attribute(:last_invoiced_amount, 500)

          expect { invoice.succeed! }.to change(invoice.user.reload, :last_invoiced_amount).from(500).to(9999)
        end

        it "increments user.total_invoiced_amount" do
          invoice.user.update_attribute(:total_invoiced_amount, 500)

          expect { invoice.succeed! }.to change(invoice.user.reload, :total_invoiced_amount).from(500).to(10499)
        end

        it "saves user" do
          old_user_last_invoiced_amount = invoice.user.last_invoiced_amount
          old_user_total_invoiced_amount = invoice.user.total_invoiced_amount

          invoice.succeed!

          invoice.user.reload
          expect(invoice.user.last_invoiced_amount).not_to eq old_user_last_invoiced_amount
          expect(invoice.user.total_invoiced_amount).not_to eq old_user_total_invoiced_amount
        end
      end

      describe "after_transition on: :succeed" do
        context "with a non-suspended user" do
          %w[open failed].each do |state|
            context "from #{state}" do
              before do
                invoice.reload.update(state: state, amount: 0)
                expect(invoice.user).to be_active
              end

              it "doesnt un-suspend the user" do
                invoice.succeed!

                expect(invoice.user.reload).to be_active
              end
            end
          end
        end

        context "with a suspended user" do
          %w[open failed].each do |state|
            context "from #{state}" do
              before do
                invoice.reload.update(state: state, amount: 0)
                invoice.user.update_attribute(:state, 'suspended')
                expect(invoice.user).to be_suspended
              end

              context "with no more open invoice" do
                it "un-suspends user" do
                  invoice.succeed!

                  expect(invoice.user.reload).to be_active
                end
              end

              context "with more failed invoice" do
                before do
                  create(:failed_invoice, site: create(:site, user: invoice.user))
                end

                it "doesnt un-suspend the user" do
                  invoice.succeed!

                  expect(invoice.user.reload).to be_suspended
                end
              end
            end
          end
        end
      end

      describe "after_transition on: :cancel" do
        it "increments user balance" do
          invoice.update_attribute(:balance_deduction_amount, 2000)
          invoice.user.update_attribute(:balance, 1000)
          expect(invoice).to be_open

          expect { invoice.cancel! }.to change(invoice.user.reload, :balance).from(1000).to(3000)

          expect(invoice).to be_canceled
        end
      end

    end # Transitions

  end # State Machine

  describe "Scopes" do
    context 'heavy setup' do
      let(:site) { create(:site) }
      let(:refunded_site) { create(:site, refunded_at: Time.now.utc) }
      before do
        @open_invoice     = create(:invoice, site: site, created_at: 48.hours.ago)
        @failed_invoice   = create(:failed_invoice, site: site, created_at: 25.hours.ago)
        @waiting_invoice  = create(:waiting_invoice, site: site, created_at: 18.hours.ago)
        @paid_invoice     = create(:paid_invoice, site: site, created_at: 16.hours.ago)
        @canceled_invoice = create(:canceled_invoice, site: site, created_at: 14.hours.ago)
        @refunded_invoice = create(:paid_invoice, site: refunded_site, created_at: 14.hours.ago)

        expect(@open_invoice).to be_open
        expect(@failed_invoice).to be_failed
        expect(@waiting_invoice).to be_waiting
        expect(@paid_invoice).to be_paid
        expect(@canceled_invoice).to be_canceled
        expect(@refunded_invoice).to be_refunded
      end

      describe '.between' do
        specify { expect(described_class.where(created_at: 24.hours.ago..15.hours.ago).order(:id)).to eq [@waiting_invoice, @paid_invoice] }
      end

      describe '.with_state' do
        specify { expect(Invoice.with_state('open').order(:id)).to eq [@open_invoice] }
        specify { expect(Invoice.with_state('failed').order(:id)).to eq [@failed_invoice] }
        specify { expect(Invoice.with_state('waiting').order(:id)).to eq [@waiting_invoice] }
      end

      describe '.paid' do
        specify { expect(Invoice.paid.order(:id)).to eq [@paid_invoice] }
      end

      describe '.refunded' do
        specify { expect(described_class.refunded.order(:id)).to eq [@refunded_invoice] }
      end

      describe '.open_or_failed' do
        specify { expect(described_class.open_or_failed.order(:id)).to eq [@open_invoice, @failed_invoice] }
      end

      describe '.not_canceled' do
        specify { expect(described_class.not_canceled.order(:id)).to eq [@open_invoice, @failed_invoice, @waiting_invoice, @paid_invoice, @refunded_invoice] }
      end

      describe '.not_paid' do
        specify { expect(described_class.not_paid.order(:id)).to eq [@open_invoice, @failed_invoice, @waiting_invoice] }
      end

      describe '.for_month & .for_period' do
        let(:open_invoice)     { create(:invoice, site: site, state: 'open') }
        let(:paid_invoice)     { create(:invoice, site: site, state: 'paid') }
        let(:canceled_invoice) { create(:invoice, site: site, state: 'canceled') }
        before do
          create(:addon_plan_invoice_item, invoice: open_invoice,     started_at: 1.month.ago.beginning_of_month, ended_at: 1.month.ago.end_of_month)
          create(:addon_plan_invoice_item, invoice: paid_invoice,     started_at: 1.month.ago.beginning_of_month, ended_at: 1.month.ago.end_of_month)
          create(:addon_plan_invoice_item, invoice: canceled_invoice, started_at: 1.month.ago.beginning_of_month, ended_at: 1.month.ago.end_of_month)
        end

        describe '.for_month' do
          specify { expect(described_class.for_month(1.months.ago).order(:id)).to eq [open_invoice, paid_invoice] }
        end

        describe '.for_period' do
          specify { expect(described_class.for_period(1.months.ago.all_month).order(:id)).to eq [open_invoice, paid_invoice] }
        end
      end
    end

    describe '.search' do
      let!(:invoice) { create(:invoice, site: site) }

      specify { expect(described_class.search(invoice.reference)).to eq [invoice] }
      specify { expect(described_class.search(invoice.site.hostname)).to eq [invoice] }
      specify { expect(described_class.search(invoice.site.dev_hostnames)).to eq [invoice] }
      specify { expect(described_class.search(invoice.user.email)).to eq [invoice] }
      specify { expect(described_class.search(invoice.user.name)).to eq [invoice] }
    end
  end # Scopes

  describe "Callbacks" do
    describe "#before_create" do
      let(:invoice) { create(:invoice) }

      it 'sets customer & site info' do
        expect(invoice.customer_full_name).to eq invoice.user.billing_name
        expect(invoice.customer_email).to eq invoice.user.billing_email
        expect(invoice.customer_country).to eq invoice.user.billing_country
        expect(invoice.customer_company_name).to eq invoice.user.company_name
        expect(invoice.customer_billing_address).to eq invoice.user.billing_address
        expect(invoice.site_hostname).to eq invoice.site.hostname
      end
    end

    describe "#after_create" do
      context "balance > invoice amount" do
        let(:user) { create(:user, billing_country: 'FR', balance: 3000) }
        let(:site) { create(:site, user: user) }
        let(:invoice) { build(:invoice, site: site, invoice_items_amount: 1000, balance_deduction_amount: 1000, amount: 0) }

        it 'succeeds the invoice and decrements its user balance' do
          invoice.save!

          expect(invoice.user.balance).to eq 2000
          expect(invoice).to be_paid
        end
      end
    end
  end

  describe "Instance Methods" do
    before do
      @invoice = build(:invoice, site: create(:site))
      @paid_plan = create(:plan)
      @paid_plan_invoice_item = create(:plan_invoice_item, invoice: @invoice, item: @paid_plan, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
      @invoice.invoice_items << @paid_plan_invoice_item
      @invoice.save!

      create(:failed_transaction, invoices: [@invoice], created_at: 4.days.ago)
      @failed_transaction2 = create(:failed_transaction, invoices: [@invoice], created_at: 3.days.ago)
      @paid_transaction = create(:paid_transaction, invoices: [@invoice], created_at: 2.days.ago)
    end
    let(:invoice) { @invoice }

    describe "#first_paid_item" do
      it { expect(invoice.reload.first_paid_item).to eq @paid_plan }
    end

    describe "#last_transaction" do
      it { expect(invoice.last_transaction).to eq @paid_transaction }
    end

  end # Instance Methods

end

# == Schema Information
#
# Table name: invoices
#
#  amount                   :integer
#  balance_deduction_amount :integer          default(0)
#  created_at               :datetime
#  customer_billing_address :text
#  customer_company_name    :string(255)
#  customer_country         :string(255)
#  customer_email           :string(255)
#  customer_full_name       :string(255)
#  id                       :integer          not null, primary key
#  invoice_items_amount     :integer
#  invoice_items_count      :integer          default(0)
#  last_failed_at           :datetime
#  paid_at                  :datetime
#  reference                :string(255)
#  renew                    :boolean          default(FALSE)
#  site_hostname            :string(255)
#  site_id                  :integer
#  state                    :string(255)
#  transactions_count       :integer          default(0)
#  updated_at               :datetime
#  vat_amount               :integer
#  vat_rate                 :float
#
# Indexes
#
#  index_invoices_on_reference  (reference) UNIQUE
#  index_invoices_on_site_id    (site_id)
#

