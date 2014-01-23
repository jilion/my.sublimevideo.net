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

    its(:user)      { should be_present }
    its(:invoices)  { should be_present }
    its(:order_id)  { should =~ /^[a-z0-9]{30}$/ }
    its(:amount)    { should eq open_invoice.amount + failed_invoice.amount }
    its(:pay_id)    { should be_nil }
    its(:nc_status) { should be_nil }
    its(:status)    { should be_nil }
    its(:error)     { should be_nil }

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

      its(:invoices) { should be_empty }
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
        new_transaction.invoices.should =~ [open_invoice, paid_invoice, failed_invoice]

        new_transaction.save!

        new_transaction.reload.invoices.should =~ [open_invoice, failed_invoice]
      end
    end

    describe "before_create :set_user_id" do
      it "should set user_id" do
        new_transaction.user.should be_nil

        new_transaction.save!

        new_transaction.reload.user.should eq open_invoice.user
      end
    end

    describe "before_save :set_fields_from_ogone_response" do
      context "with no response from OgoneWrapper" do
        it "should not set OgoneWrapper specific fields" do
          new_transaction.instance_variable_set(:@ogone_response_info, nil)

          new_transaction.save!

          new_transaction.pay_id.should be_nil
          new_transaction.status.should be_nil
          new_transaction.error.should  be_nil
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

          new_transaction.pay_id.should    eq "123"
          new_transaction.nc_status.should eq 0
          new_transaction.status.should    eq 9
          new_transaction.error.should     eq "!"
        end
      end
    end

    describe "before_create :set_amount" do
      it "should set transaction amount to the sum of all its invoices amount" do
        new_transaction.amount.should be_nil

        new_transaction.save!

        new_transaction.reload.amount.should eq open_invoice.amount + failed_invoice.amount
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

              transaction.state.should eq 'waiting_d3d'
            end
          end
        end

        %w[waiting_d3d failed paid].each do |state|
          context "from #{state} state" do
            before { transaction.update_attribute(:state, state) }

            it 'does not change the state' do
              transaction.wait_d3d

              transaction.state.should eq state
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

              transaction.state.should eq 'paid'
            end
          end
        end

        %w[failed paid].each do |state|
          context "from #{state} state" do
            before { transaction.update_attribute(:state, state) }

            it 'does not change the state' do
              transaction.succeed

              transaction.state.should eq state
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

              transaction.state.should eq 'failed'
            end
          end
        end

        %w[failed paid].each do |state|
          context "from #{state} state" do
            before { transaction.update_attribute(:state, state) }

            it 'does not change the state' do
              transaction.fail

              transaction.state.should eq state
            end
          end
        end
      end
    end # Events

    describe "Transitions" do
      describe "after_transition on: [:succeed, :fail], do: :update_invoices" do
        describe "on :succeed" do
          it 'calls succeed on each of the transaction invoices' do
            open_invoice.should_receive(:succeed!)
            failed_invoice.should_receive(:succeed!)

            transaction.succeed
          end
        end

        describe "on :fail" do
          it 'calls fail on each of the transaction invoices' do
            open_invoice.should_receive(:fail!)
            failed_invoice.should_receive(:fail!)

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
      specify { Transaction.failed.should =~ [@failed_transaction] }
    end
  end # Scopes

  describe "Instance Methods" do

    describe "#description" do
      subject { create(:transaction, invoices: [open_invoice, failed_invoice]) }

      it "should create a description with invoices references" do
        subject.description.should eq "##{open_invoice.reference},##{failed_invoice.reference}"
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

