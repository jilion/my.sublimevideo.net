require 'spec_helper'

describe Transaction, :vcr do
  let(:user)            { create(:user) }
  let(:site1)           { create(:site, user: user) }
  let(:site2)           { create(:site, user: user) }
  let(:open_invoice)    { create(:invoice, site: site1) }
  let(:failed_invoice)  { create(:failed_invoice, site: site2) }
  let(:paid_invoice)    { create(:paid_invoice, site: site2) }
  let(:new_transaction) { build(:transaction, invoices: [open_invoice, paid_invoice, failed_invoice]) }
  let(:transaction)     { create(:transaction, invoices: [open_invoice, paid_invoice, failed_invoice]) }

  context "Factory" do
    subject { transaction }

    describe '#user' do
      subject { super().user }
      it      { should be_present }
    end

    describe '#invoices' do
      subject { super().invoices }
      it  { should be_present }
    end

    describe '#order_id' do
      subject { super().order_id }
      it  { should =~ /^[a-z0-9]{30}$/ }
    end

    describe '#amount' do
      subject { super().amount }
      it    { should eq open_invoice.amount + failed_invoice.amount }
    end

    describe '#pay_id' do
      subject { super().pay_id }
      it    { should be_nil }
    end

    describe '#nc_status' do
      subject { super().nc_status }
      it { should be_nil }
    end

    describe '#status' do
      subject { super().status }
      it    { should be_nil }
    end

    describe '#error' do
      subject { super().error }
      it     { should be_nil }
    end

    it { should be_unprocessed } # initial state
    it { should be_valid }
  end # Factory

  describe "Associations" do
    it { should belong_to :user }
    it { should have_and_belong_to_many :invoices }
  end # Associations

  describe "Validations" do
    describe "#at_least_one_invoice" do
      # subject { build(:transaction) }

      describe '#invoices' do
        subject { super().invoices }
        it { should be_empty }
      end
      specify { should_not be_valid }
      specify { should have(1).error_on(:base) }
    end

    describe "#all_invoices_belong_to_same_user" do
      subject { build(:transaction, invoices: [create(:invoice, site: create(:site)), create(:invoice, site: create(:site))]) }

      specify { should_not be_valid }
      specify { should have(1).error_on(:base) }
    end

    describe "#minimum_amount" do
      subject { build(:transaction, invoices: [create(:invoice, site: create(:site), amount: 50), create(:invoice, site: create(:site), amount: 49)]) }

      specify { should_not be_valid }
      specify { should have(1).error_on(:amount) }
    end
  end # Validations

  describe "Callbacks" do
    describe "before_create :reject_paid_invoices" do
      it "should reject any paid invoices" do
        expect(new_transaction.invoices).to match_array([open_invoice, paid_invoice, failed_invoice])

        new_transaction.save!

        expect(new_transaction.reload.invoices).to match_array([open_invoice, failed_invoice])
      end
    end

    describe "before_create :set_user_id" do
      it "should set user_id" do
        expect(new_transaction.user).to be_nil

        new_transaction.save!

        expect(new_transaction.reload.user).to eq open_invoice.user
      end
    end

    describe "before_save :set_fields_from_ogone_response" do
      context "with no response from OgoneWrapper" do
        it "should not set OgoneWrapper specific fields" do
          new_transaction.instance_variable_set(:@ogone_response_info, nil)

          new_transaction.save!

          expect(new_transaction.pay_id).to be_nil
          expect(new_transaction.status).to be_nil
          expect(new_transaction.error).to  be_nil
        end
      end

      context "with a response from OgoneWrapper" do
        it "should set OgoneWrapper specific fields" do
          new_transaction.instance_variable_set(:@ogone_response_info, {
            "PAYID" => "123",
            "ACCEPTANCE" => "321",
            "NCSTATUS" => "0",
            "STATUS" => "9",
            "ECI" => "7",
            "NCERROR" => "0",
            "NCERRORPLUS" => "!"
          })

          new_transaction.save!

          expect(new_transaction.pay_id).to    eq "123"
          expect(new_transaction.nc_status).to eq 0
          expect(new_transaction.status).to    eq 9
          expect(new_transaction.error).to     eq "!"
        end
      end
    end

    describe "before_create :set_amount" do
      it "should set transaction amount to the sum of all its invoices amount" do
        expect(new_transaction.amount).to be_nil

        new_transaction.save!

        expect(new_transaction.reload.amount).to eq open_invoice.amount + failed_invoice.amount
      end
    end
  end # Callbacks

  describe "State Machine" do
    subject { transaction }

    it { should be_unprocessed }

    describe "Events" do
      describe "#wait_d3d" do
        %w[unprocessed].each do |state|
          context "from #{state} state" do
            before { transaction.update_attribute(:state, state) }

            it 'sets the state to waiting_d3d' do
              transaction.wait_d3d

              expect(transaction.state).to eq 'waiting_d3d'
            end
          end
        end

        %w[waiting_d3d failed paid].each do |state|
          context "from #{state} state" do
            before { transaction.update_attribute(:state, state) }

            it 'does not change the state' do
              transaction.wait_d3d

              expect(transaction.state).to eq state
            end
          end
        end
      end

      describe "#succeed" do
        %w[unprocessed waiting_d3d].each do |state|
          context "from #{state} state" do
            before { transaction.update_attribute(:state, state) }

            it 'sets the state to paid' do
              transaction.succeed

              expect(transaction.state).to eq 'paid'
            end
          end
        end

        %w[failed paid].each do |state|
          context "from #{state} state" do
            before { transaction.update_attribute(:state, state) }

            it 'does not change the state' do
              transaction.succeed

              expect(transaction.state).to eq state
            end
          end
        end
      end

      describe "#fail" do
        %w[unprocessed waiting_d3d].each do |state|
          context "from #{state} state" do
            before { transaction.update_attribute(:state, state) }

            it 'sets the state to failed' do
              transaction.fail

              expect(transaction.state).to eq 'failed'
            end
          end
        end

        %w[failed paid].each do |state|
          context "from #{state} state" do
            before { transaction.update_attribute(:state, state) }

            it 'does not change the state' do
              transaction.fail

              expect(transaction.state).to eq state
            end
          end
        end
      end
    end # Events

    describe "Transitions" do
      describe "after_transition on: [:succeed, :fail], do: :update_invoices" do
        describe "on :succeed" do
          it 'calls succeed on each of the transaction invoices' do
            expect(open_invoice).to receive(:succeed!)
            expect(failed_invoice).to receive(:succeed!)

            transaction.succeed
          end
        end

        describe "on :fail" do
          it 'calls fail on each of the transaction invoices' do
            expect(open_invoice).to receive(:fail!)
            expect(failed_invoice).to receive(:fail!)

            transaction.fail
          end
        end
      end

      describe "after_transition on: :succeed, do: :send_charging_succeeded_email" do
        context "from open" do
          it "should send an email to invoice.user" do
            expect(BillingMailer).to delay(:transaction_succeeded).with(transaction.id)
            transaction.succeed
          end
        end
      end

      describe "after_transition on: :fail, do: :send_charging_failed_email" do
        context "from open" do
          it "should send an email to invoice.user" do
            expect(BillingMailer).to delay(:transaction_failed).with(transaction.id)
            transaction.fail
          end
        end
      end
    end # Transitions

  end # State Machine

  describe "Scopes" do
    before do
      create(:transaction, invoices: [open_invoice])
      @failed_transaction = create(:failed_transaction, invoices: [open_invoice])
      create(:paid_transaction, invoices: [open_invoice])
    end

    describe "#failed" do
      specify { expect(Transaction.failed).to match_array([@failed_transaction]) }
    end
  end # Scopes

  describe "Class Methods" do

    describe ".charge_invoices" do
      let(:suspended_user) { create(:user, state: 'suspended') }
      before do
        @site3     = create(:site, user: suspended_user)
        @invoice1  = create(:invoice, state: 'open', site: site1)
        @invoice11 = create(:invoice, state: 'open', site: site1) # second open invoice for the same user
        @invoice2  = create(:invoice, state: 'open', site: @site3)
        @invoice3  = create(:failed_invoice, site: site1)
        @invoice4  = create(:failed_invoice, site: @site3) # user is not active
        @invoice5  = create(:paid_invoice, site: site1)
      end

      it "delays invoice charging for each active user (and only once!) with open or failed invoices" do
        expect(Transaction).to delay(:charge_invoices_by_user_id).with(site1.user.id)

        Transaction.charge_invoices
      end

      it "delays invoice charging only once per user" do
        allow(Transaction).to receive(:delay) { double(charge_invoices_by_user_id: true) }
        expect(Transaction).to receive(:delay).once

        Transaction.charge_invoices
      end
    end # .charge_invoices

    describe ".charge_invoices_by_user_id" do
      let(:user) { create(:user_no_cc, valid_cc_attributes) }
      before do
        allow(NewsletterSubscriptionManager).to receive(:subscribe)
        user2 = create(:user_no_cc, valid_cc_attributes)
        site3 = create(:site, user: user2)
        @invoice1 = create(:invoice, site: site1, state: 'paid') # first invoice
        @invoice2 = create(:invoice, site: site1, state: 'failed')
        @invoice3 = create(:invoice, site: site1, state: 'open')
        @invoice4 = create(:invoice, site: site3, state: 'open')
      end

      it "delays invoice charging for failed & open invoices" do
        expect(@invoice1.reload).to be_paid
        expect(@invoice2.reload).to be_failed
        expect(@invoice3.reload).to be_open
        expect(Transaction).to receive(:charge_by_invoice_ids).with([@invoice2.id, @invoice3.id]).and_return(an_instance_of(Transaction))

        Transaction.charge_invoices_by_user_id(user.id)
      end

      it "charges invoices" do
        expect(@invoice1.reload).to be_paid
        expect(@invoice2.reload).to be_failed
        expect(@invoice3.reload).to be_open

        Transaction.charge_invoices_by_user_id(user.id)

        expect(@invoice1.reload).to be_paid
        expect(@invoice2.reload).to be_paid
        expect(@invoice3.reload).to be_paid
      end

      context "invoice with 15 failed transactions or more" do
        it "doesn't try to charge the invoice" do
          15.times { create(:transaction, invoices: [@invoice2], state: 'failed') }
          expect(Transaction).not_to receive(:charge_by_invoice_ids)

          Transaction.charge_invoices_by_user_id(user.id)

          expect(@invoice2.reload).to be_failed
        end

        context "invoice is not the first one" do
          context "user is not a vip" do
            it "suspend the user" do
              15.times { create(:transaction, invoices: [@invoice2], state: 'failed') }
              expect(Transaction).not_to receive(:charge_by_invoice_ids)

              Transaction.charge_invoices_by_user_id(user.id)

              expect(@invoice2.reload).to be_failed
              expect(user.reload).to be_suspended
            end
          end

          context "user is a vip" do
            before do
              user.update_attribute(:vip, true)
            end

            it "doesn't suspend the user" do
              15.times { create(:transaction, invoices: [@invoice2], state: 'failed') }
              expect(Transaction).not_to receive(:charge_by_invoice_ids)

              Transaction.charge_invoices_by_user_id(user.id)

              expect(@invoice2.reload).to be_failed
              expect(user.reload).to be_active
            end
          end
        end
      end
    end # .charge_invoices_by_user_id

    describe ".charge_by_invoice_ids" do
      let(:user) { create(:user_no_cc, valid_cc_attributes) }

      context "with a credit card alias" do
        it "charges OgoneWrapper for the total amount of the open and failed invoices" do
          expect(OgoneWrapper).to receive(:purchase).with(open_invoice.amount + failed_invoice.amount, user.cc_alias, {
            order_id: an_instance_of(String),
            description: an_instance_of(String),
            email: user.reload.email,
            billing_address: {
              address1: user.billing_address_1,
              zip: user.billing_postal_code,
              city: user.billing_city,
              country: user.billing_country
            },
            paramplus: "PAYMENT=TRUE"
          })
          Transaction.charge_by_invoice_ids([open_invoice.id, failed_invoice.id, paid_invoice.id])
        end

        it "stores cc info from the user's cc info" do
          Transaction.charge_by_invoice_ids([open_invoice.id, failed_invoice.id, paid_invoice.id])

          expect(open_invoice.last_transaction.cc_type).to        eq user.cc_type
          expect(open_invoice.last_transaction.cc_last_digits).to eq user.cc_last_digits
          expect(open_invoice.last_transaction.cc_expire_on).to   eq user.cc_expire_on
        end
      end

      context "with a succeeding purchase" do
        context "credit card" do
          it "sets transaction and invoices to paid state" do
            expect(open_invoice).to be_open
            expect(Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })).to be_truthy
            expect(open_invoice.last_transaction).to be_paid
            expect(open_invoice.reload).to be_paid
          end
        end

        context "alias" do
          it "sets transaction and invoices to paid state" do
            expect(open_invoice).to be_open
            expect(Transaction.charge_by_invoice_ids([open_invoice.id])).to be_truthy
            expect(open_invoice.last_transaction).to be_paid
            expect(open_invoice.reload).to be_paid
          end
        end

        context "with a purchase that need a 3d secure authentication" do
          before do
            allow(OgoneWrapper).to receive(:purchase) { double('response', params: { "NCSTATUS" => "5", "STATUS" => "46", "NCERRORPLUS" => "!" }) }
          end

          context "alias" do
            it "should set transaction and invoices to waiting_d3d state" do
              expect(open_invoice).to be_open
              expect(Transaction.charge_by_invoice_ids([open_invoice.id])).to be_truthy
              expect(open_invoice.last_transaction).to be_failed
              expect(open_invoice.last_transaction.error).to eq "!"
              expect(open_invoice.reload).to be_failed
            end
          end
        end
      end

      context "with a failing purchase" do
        context "with a purchase that raise an error" do
          before { allow(OgoneWrapper).to receive(:purchase).and_raise("Purchase error!") }
          it "should set transaction and invoices to failed state" do
            expect(open_invoice).to be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            expect(open_invoice.last_transaction).to be_unprocessed
            expect(open_invoice.reload).to be_open
          end
        end

        context "with a failing purchase due to an invalid credit card" do
          before { allow(OgoneWrapper).to receive(:purchase) { double('response', params: { "NCSTATUS" => "5", "STATUS" => "0", "NCERRORPLUS" => "invalid" }) } }
          it "should set transaction and invoices to failed state" do
            expect(open_invoice).to be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            expect(open_invoice.last_transaction).to be_failed
            expect(open_invoice.reload).to be_failed
          end
        end

        context "with a failing purchase due to a refused purchase" do
          before { allow(OgoneWrapper).to receive(:purchase) { double('response', params: { "NCSTATUS" => "3", "STATUS" => "93", "NCERRORPLUS" => "refused" }) } }
          it "should set transaction and invoices to failed state" do
            expect(open_invoice).to be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            expect(open_invoice.reload).to be_failed
          end
        end

        context "with a failing purchase due to a waiting authorization" do
          before { allow(OgoneWrapper).to receive(:purchase) { double('response', params: { "NCSTATUS" => "0", "STATUS" => "51", "NCERRORPLUS" => "waiting" }) } }
          it "should not succeed nor fail transaction nor invoices" do
            expect(open_invoice).to be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            expect(open_invoice.last_transaction).to be_waiting
            expect(open_invoice.reload).to be_waiting
          end
        end

        context "with a failing purchase due to a uncertain result" do
          before { allow(OgoneWrapper).to receive(:purchase) { double('response', params: { "NCSTATUS" => "2", "STATUS" => "92", "NCERRORPLUS" => "unknown" }) } }
          it "should not succeed nor fail transaction nor invoices, with status 2" do
            expect(open_invoice).to be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            expect(open_invoice.last_transaction).to be_waiting
            expect(open_invoice.reload).to be_waiting
          end
        end

      end

    end # .charge_by_invoice_ids

  end # Class Methods

  describe "Instance Methods" do

    describe "#process_payment_response" do
      before do
        @d3d_params = {
          "PAYID" => "123",
          "ACCEPTANCE" => "321",
          "STATUS" => "46",
          "ECI" => "7",
          "NCERROR" => "0",
          "NCERRORPLUS" => "!",
          "HTML_ANSWER" => Base64.encode64("<html>No HTML.</html>")
        }
        @success_params = {
          "PAYID" => "123",
          "ACCEPTANCE" => "321",
          "NCSTATUS" => "0",
          "STATUS" => "9",
          "ECI" => "7",
          "NCERROR" => "0",
          "NCERRORPLUS" => "!"
        }
        @waiting_params = {
          "PAYID" => "123",
          "ACCEPTANCE" => "321",
          "NCSTATUS" => "0",
          "STATUS" => "51",
          "ECI" => "7",
          "NCERROR" => "0",
          "NCERRORPLUS" => "waiting"
        }
        @invalid_params = {
          "PAYID" => "123",
          "ACCEPTANCE" => "321",
          "NCSTATUS" => "5",
          "STATUS" => "0",
          "ECI" => "7",
          "NCERROR" => "0",
          "NCERRORPLUS" => "invalid"
        }
        @refused_params = {
          "PAYID" => "123",
          "ACCEPTANCE" => "321",
          "NCSTATUS" => "3",
          "STATUS" => "93",
          "ECI" => "7",
          "NCERROR" => "30303",
          "NCERRORPLUS" => "refused"
        }
        @unknown_params = {
          "PAYID" => "123",
          "ACCEPTANCE" => "321",
          "NCSTATUS" => "2",
          "STATUS" => "92",
          "ECI" => "7",
          "NCERROR" => "20202",
          "NCERRORPLUS" => "unknown"
        }
      end
      subject { create(:transaction, invoices: [open_invoice, failed_invoice]) }

      context "STATUS is 9" do
        it "puts transaction in 'paid' state" do
          expect(subject).to be_unprocessed

          subject.process_payment_response(@success_params)

          expect(subject.reload).to   be_paid
          expect(open_invoice.reload).to be_paid
          expect(failed_invoice.reload).to be_paid
        end
      end

      context "STATUS is 51" do
        it "puts transaction in 'waiting' state" do
          expect(subject).to be_unprocessed

          subject.process_payment_response(@waiting_params)

          expect(subject.reload).to    be_waiting
          expect(subject.nc_status).to eq 0
          expect(subject.status).to    eq 51
          expect(subject.error).to     eq "waiting"
          expect(open_invoice.reload).to  be_waiting
          expect(failed_invoice.reload).to  be_waiting
        end
      end

      context "STATUS is 0" do
        it "puts transaction in 'failed' state" do
          expect(subject).to be_unprocessed

          subject.process_payment_response(@invalid_params)

          expect(subject.reload).to    be_failed
          expect(subject.nc_status).to eq 5
          expect(subject.status).to    eq 0
          expect(subject.error).to     eq "invalid"
          expect(open_invoice.reload).to  be_failed
          expect(failed_invoice.reload).to  be_failed
        end
      end

      context "STATUS is 46" do
        it "puts transaction in 'failed' state" do
          expect(subject).to be_unprocessed
          expect(subject.error).to be_nil

          subject.process_payment_response(@d3d_params)

          expect(subject.reload).to   be_failed
          expect(subject.error).to    eq "!"
          expect(open_invoice.reload).to be_failed
          expect(failed_invoice.reload).to be_failed
        end
      end

      context "STATUS is 93" do
        it "puts transaction in 'failed' state" do
          expect(subject).to be_unprocessed

          subject.process_payment_response(@refused_params)

          expect(subject.reload).to    be_failed
          expect(subject.nc_status).to eq 3
          expect(subject.status).to    eq 93
          expect(subject.error).to     eq "refused"

          expect(open_invoice.reload).to be_failed
          expect(failed_invoice.reload).to be_failed
        end
      end

      context "STATUS is 92" do
        it "puts transaction in 'waiting' state" do
          expect(subject).to be_unprocessed
          expect(Notifier).to receive(:send)

          subject.process_payment_response(@unknown_params)

          expect(subject.reload).to    be_waiting
          expect(subject.nc_status).to eq 2
          expect(subject.status).to    eq 92
          expect(subject.error).to     eq "unknown"

          expect(open_invoice.reload).to be_waiting
          expect(failed_invoice.reload).to be_waiting
        end
      end

      context "first STATUS is 51, second is 9" do
        it "puts transaction in 'waiting' state, and then puts it in 'paid' state" do
          expect(subject).to be_unprocessed

          subject.process_payment_response(@waiting_params)

          expect(subject.reload).to    be_waiting
          expect(subject.nc_status).to eq 0
          expect(subject.status).to    eq 51
          expect(subject.error).to     eq "waiting"
          expect(subject).to be_waiting

          expect(open_invoice.reload).to be_waiting
          expect(failed_invoice.reload).to be_waiting

          subject.process_payment_response(@success_params)

          expect(subject.reload).to    be_paid
          expect(subject.nc_status).to eq 0
          expect(subject.status).to    eq 9
          expect(subject.error).to     eq "!"

          expect(open_invoice.reload).to be_paid
          expect(failed_invoice.reload).to be_paid
        end
      end

      context "first STATUS is 92, second is 9" do
        it "puts transaction in 'waiting' state, and then puts it in 'paid' state" do
          expect(subject).to be_unprocessed
          expect(Notifier).to receive(:send)

          subject.process_payment_response(@unknown_params)

          expect(subject.reload).to    be_waiting
          expect(subject.nc_status).to eq 2
          expect(subject.status).to    eq 92
          expect(subject.error).to     eq "unknown"

          expect(open_invoice.reload).to be_waiting
          expect(failed_invoice.reload).to be_waiting

          subject.process_payment_response(@success_params)

          expect(subject.reload).to be_paid
          expect(subject.nc_status).to eq 0
          expect(subject.status).to    eq 9
          expect(subject.error).to     eq "!"

          expect(open_invoice.reload).to be_paid
          expect(failed_invoice.reload).to be_paid
        end
      end
    end

    describe "#description" do
      subject { create(:transaction, invoices: [open_invoice, failed_invoice]) }

      it "should create a description with invoices references" do
        expect(subject.description).to eq "##{open_invoice.reference},##{failed_invoice.reference}"
      end
    end

  end

end

# == Schema Information
#
# Table name: transactions
#
#  amount         :integer
#  cc_expire_on   :date
#  cc_last_digits :string(255)
#  cc_type        :string(255)
#  created_at     :datetime
#  error          :text
#  id             :integer          not null, primary key
#  nc_status      :integer
#  order_id       :string(255)
#  pay_id         :string(255)
#  state          :string(255)
#  status         :integer
#  updated_at     :datetime
#  user_id        :integer
#
# Indexes
#
#  index_transactions_on_order_id  (order_id) UNIQUE
#

