require 'spec_helper'

describe Transaction do

  context "Factory" do
    before(:all) { @transaction = Factory(:transaction, :invoices => [Factory(:invoice)]) }
    subject { @transaction }

    its(:user)           { should be_present }
    its(:invoices)       { should be_present }
    its(:cc_type)        { should == 'visa' }
    its(:cc_last_digits) { should == 1111 }
    its(:cc_expire_on)   { should == 1.year.from_now.end_of_month.to_date }
    its(:amount)         { should == 9900 }
    its(:error)          { should be_nil }

    it { should be_open } # initial state
    it { should be_valid }
  end

  describe "Associations" do
    before(:all) { @transaction = Factory(:transaction, :invoices => [Factory(:invoice)]) }
    subject { @transaction }

    it { should belong_to :user }
    it { should have_and_belong_to_many :invoices }
  end

  pending "Scopes" do
    before(:all) do
    end
  end

  describe "Validations" do
    [:cc_type, :cc_last_digits, :cc_expire_on, :amount].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:cc_type) }
    it { should validate_presence_of(:cc_last_digits) }
    it { should validate_presence_of(:cc_expire_on) }
    it { should validate_presence_of(:amount) }

    it { should validate_numericality_of(:amount) }
    it { should validate_numericality_of(:cc_last_digits) }

    describe "#at_least_one_invoice" do
      before(:all) { @transaction = Factory.build(:transaction) }
      subject { @transaction }

      specify { subject.invoices.should be_empty }
      specify { subject.should_not be_valid }
      specify { subject.should have(1).error_on(:base) }
    end
  end # Validations

  describe "State Machine" do
    before(:all) do
      @invoice1 = Factory(:invoice)
      @invoice2 = Factory(:invoice)
      @transaction = Factory(:transaction, :invoices => [@invoice1, @invoice2])
    end
    subject { @transaction }

    describe "Initial state" do
      it { should be_open }
    end

    pending "Events" do

      describe "#fail" do
        context "from unpaid state" do
          before(:each) { subject.reload.update_attribute(:state, 'unpaid') }

          context "while attempts < Billing.max_charging_attempts" do
            (1...Billing.max_charging_attempts).each do |attempts|
              it "should set invoice to unpaid if it's the attempt ##{attempts}" do
                subject.attempts = attempts
                subject.fail
                subject.should be_unpaid
              end
            end
          end

          context "when attempts > Billing.max_charging_attempts" do
            (Billing.max_charging_attempts+1..Billing.max_charging_attempts+2).each do |attempts|
              it "should set invoice to failed if it's the attempt ##{attempts}" do
                subject.attempts = attempts
                subject.fail
                subject.should be_failed
              end
            end
          end
        end

        context "from failed state" do
          before(:each) { subject.reload.update_attribute(:state, 'failed') }

          context "while attempts < Billing.max_charging_attempts" do
            it "should set invoice to failed " do
              subject.should be_failed
              subject.fail
              subject.should be_failed
            end
          end
        end
      end

      describe "#succeed" do
        %w[unpaid failed].each do |state|
          context "from #{state} state" do
            before(:each) { subject.reload.update_attribute(:state, state) }

            it "should set invoice to paid" do
              subject.succeed
              subject.should be_paid
            end
          end
        end
      end

    end # Events

    describe "Transitions" do

      describe "after_transition :on => [:succeed, :fail], :do => :update_invoices" do
        describe "initial invoices state" do
          specify do
            @invoice1.should be_open
            @invoice1.paid_at.should be_nil
            @invoice1.failed_at.should be_nil
            @invoice2.should be_open
            @invoice2.paid_at.should be_nil
            @invoice2.failed_at.should be_nil
          end
        end

        describe "on :succeed" do
          before(:each) { subject.reload.succeed }

          specify do
            @invoice1.reload.should be_paid
            @invoice1.paid_at.to_i.should == subject.updated_at.to_i
            @invoice1.failed_at.should be_nil
            @invoice2.reload.should be_paid
            @invoice2.paid_at.to_i.should == subject.updated_at.to_i
            @invoice2.failed_at.should be_nil
          end
        end

        describe "on :fail" do
          before(:each) { subject.reload.fail }

          specify do
            @invoice1.reload.should be_failed
            @invoice1.paid_at.should be_nil
            @invoice1.failed_at.to_i.should == subject.updated_at.to_i
            @invoice2.reload.should be_failed
            @invoice2.paid_at.should be_nil
            @invoice2.failed_at.to_i.should == subject.updated_at.to_i
          end
        end
      end

    end # Transitions

  end # State Machine


end

# == Schema Information
#
# Table name: transactions
#
#  id             :integer         not null, primary key
#  user_id        :integer
#  cc_type        :string(255)
#  cc_last_digits :integer
#  cc_expire_on   :date
#  state          :string(255)
#  amount         :integer
#  error          :text
#  created_at     :datetime
#  updated_at     :datetime
#

