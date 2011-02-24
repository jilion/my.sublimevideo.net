require 'spec_helper'

describe Transaction do

  context "Factory" do
    
    before(:all) { @transaction = Factory(:transaction, invoices: [Factory(:invoice, amount: 1000, state: 'unpaid')]) }
    subject { @transaction }

    its(:user)           { should be_present }
    its(:invoices)       { should be_present }
    its(:cc_type)        { should == 'visa' }
    its(:cc_last_digits) { should == @transaction.user.cc_last_digits }
    its(:cc_expire_on)   { should == @transaction.user.cc_expire_on }
    its(:amount)         { should == 1000 }
    its(:error)          { should be_nil }

    it { should be_open } # initial state
    it { should be_valid }
  end # Factory

  describe "Associations" do
    it { should belong_to :user }
    it { should have_and_belong_to_many :invoices }
  end # Associations

  describe "Validations" do
    describe "#at_least_one_invoice" do
      before(:all) { @transaction = Factory.build(:transaction) }
      subject { @transaction }

      specify { subject.invoices.should be_empty }
      specify { subject.should_not be_valid }
      specify { subject.should have(1).error_on(:base) }
    end

    describe "#all_invoices_belong_to_same_user" do
      before(:all) do
        site1 = Factory(:site)
        site2 = Factory(:site)
        @transaction = Factory.build(:transaction, invoices: [Factory(:invoice, site: site1), Factory(:invoice, site: site2)])
      end
      subject { @transaction }

      specify { subject.should_not be_valid }
      specify { subject.should have(1).error_on(:base) }
    end
  end # Validations

  describe "Callbacks" do
    before(:all) do
      @site = Factory(:site)
      @invoice1 = Factory(:invoice, site: @site, amount: 100, state: 'open')
      @invoice2 = Factory(:invoice, site: @site, amount: 200, state: 'unpaid')
      @invoice3 = Factory(:invoice, site: @site, amount: 300, state: 'paid')
      @invoice4 = Factory(:invoice, site: @site, amount: 400, state: 'failed')
    end
    subject { @transaction }

    describe "before_create :reject_open_and_paid_invoices" do
      it "should reject any open or paid invoices" do
        transaction = Factory.build(:transaction, invoices: [@invoice1, @invoice2, @invoice3, @invoice4])
        transaction.invoices.should == [@invoice1, @invoice2, @invoice3, @invoice4]
        transaction.save!
        transaction.reload.invoices.should == [@invoice2, @invoice4]
      end
    end

    describe "before_create :set_user_id" do
      it "should set user_id" do
        transaction = Factory.build(:transaction, invoices: [@invoice1, @invoice2, @invoice3, @invoice4])
        transaction.user.should be_nil
        transaction.save!
        transaction.reload.user.should == @invoice1.user
      end
    end

    describe "before_create :set_cc_infos" do
      it "should set cc_type, cc_last_digits and cc_expire_on" do
        transaction = Factory.build(:transaction, invoices: [@invoice1, @invoice2, @invoice3, @invoice4])
        transaction.user.should be_nil
        transaction.save!
        transaction.reload.cc_type.should == @invoice1.user.cc_type
        transaction.cc_last_digits.should == @invoice1.user.cc_last_digits
        transaction.cc_expire_on.should == @invoice1.user.cc_expire_on
      end
    end

    describe "before_create :set_amount" do
      it "should set transaction amount to the sum of all its invoices amount" do
        transaction = Factory.build(:transaction, invoices: [@invoice1, @invoice2, @invoice3, @invoice4])
        transaction.amount.should be_nil
        transaction.save!
        transaction.reload.amount.should == 600
      end
    end
  end # Callbacks

  describe "State Machine" do
    before(:all) do
      @site        = Factory(:site)
      @invoice1    = Factory(:invoice, site: @site, state: 'unpaid')
      @invoice2    = Factory(:invoice, site: @site, state: 'failed')
      @transaction = Factory(:transaction, invoices: [@invoice1, @invoice2])
    end
    subject { @transaction }

    describe "Initial state" do
      it { should be_open }
    end

    describe "Events" do

      describe "#succeed" do
        context "from open state" do
          before(:each) { subject.reload }

          it "should set transaction to paid" do
            subject.succeed
            subject.should be_paid
          end
        end
      end

      describe "#fail" do
        context "from open state" do
          before(:each) { subject.reload }

          it "should set transaction to failed" do
            subject.fail
            subject.should be_failed
          end
        end
      end

    end # Events

    describe "Transitions" do

      describe "after_transition on: [:succeed, :fail], do: :update_invoices" do
        describe "initial invoices state" do
          specify do
            @invoice1.should be_unpaid
            @invoice1.paid_at.should be_nil
            @invoice1.failed_at.should be_nil
            @invoice2.should be_failed
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

  describe "Scopes" do
    before(:all) do
      @site               = Factory(:site)
      @invoice            = Factory(:invoice, site: @site, state: 'unpaid')
      @transaction_open   = Factory(:transaction, invoices: [@invoice])
      @transaction_failed = Factory(:transaction, invoices: [@invoice], state: 'failed')
      @transaction_paid   = Factory(:transaction, invoices: [@invoice], state: 'paid')
    end

    describe "#failed" do
      specify { Transaction.failed.all.should =~ [@transaction_failed] }
    end
  end # Scopes

  describe "Class Methods" do

    describe ".charge_by_invoice_ids" do
      context "with a succeeding purchase" do
        use_vcr_cassette "ogone_visa_payment_2000_alias"

        context "given unpaid invoices" do
          before(:all) do
            @site     = Factory(:site)
            @invoice1 = Factory(:invoice, site: @site, state: 'unpaid')
            @invoice2 = Factory(:invoice, site: @site, state: 'unpaid')
          end
          subject { Transaction.charge_by_invoice_ids([@invoice1.id, @invoice2.id]) }

          it "should charge Ogone for the total amount of the invoices" do
            Ogone.should_receive(:purchase).with(@invoice1.amount + @invoice2.amount, @invoice1.user.credit_card_alias, { :order_id => an_instance_of(Fixnum), :currency => 'USD' })
            subject
          end

          it "should set transaction and invoices to paid state" do
            subject.reload.should be_paid
            @invoice1.reload.should be_paid
            @invoice2.reload.should be_paid
          end
        end

        context "given invoices with mixed-state" do
          before(:all) do
            @site     = Factory(:site)
            @invoice1 = Factory(:invoice, site: @site, state: 'unpaid')
            @invoice2 = Factory(:invoice, site: @site, state: 'failed')
            @invoice3 = Factory(:invoice, site: @site, state: 'paid')
          end
          subject { Transaction.charge_by_invoice_ids([@invoice1.id, @invoice2.id, @invoice3.id]) }

          it "should charge Ogone for the total amount of the invoices" do
            Ogone.should_receive(:purchase).with(@invoice1.amount + @invoice2.amount, @invoice1.user.credit_card_alias, { :order_id => an_instance_of(Fixnum), :currency => 'USD' })
            subject
          end

          it "should set transaction and invoices to paid state" do
            subject.reload.should be_paid
            @invoice1.reload.should be_paid
            @invoice2.reload.should be_paid
            @invoice3.reload.should be_paid
          end
        end
      end

      context "with a failing purchase" do
        use_vcr_cassette "ogone_visa_payment_9999"

        context "given unpaid invoices" do
          before(:all) do
            @site     = Factory(:site)
            @invoice1 = Factory(:invoice, site: @site, state: 'unpaid')
            @invoice2 = Factory(:invoice, site: @site, state: 'unpaid')
          end
          subject { Transaction.charge_by_invoice_ids([@invoice1.id, @invoice2.id]) }

          it "should charge Ogone for the total amount of the invoices" do
            Ogone.should_receive(:purchase).with(@invoice1.amount + @invoice2.amount, @invoice1.user.credit_card_alias, { :order_id => an_instance_of(Fixnum), :currency => 'USD' })
            subject
          end

          it "should set transaction and invoices to paid state" do
            subject.reload.should be_failed
            @invoice1.reload.should be_failed
            @invoice2.reload.should be_failed
          end
        end

        context "given invoices with mixed-state" do
          before(:all) do
            @site     = Factory(:site)
            @invoice1 = Factory(:invoice, site: @site, state: 'unpaid')
            @invoice2 = Factory(:invoice, site: @site, state: 'failed')
            @invoice3 = Factory(:invoice, site: @site, state: 'paid')
          end
          subject { Transaction.charge_by_invoice_ids([@invoice1.id, @invoice2.id, @invoice3.id]) }

          it "should charge Ogone for the total amount of the invoices" do
            Ogone.should_receive(:purchase).with(@invoice1.amount + @invoice2.amount, @invoice1.user.credit_card_alias, { :order_id => an_instance_of(Fixnum), :currency => 'USD' })
            subject
          end

          it "should set transaction and invoices to paid state" do
            subject.reload.should be_failed
            @invoice1.reload.should be_failed
            @invoice2.reload.should be_failed
            @invoice3.reload.should be_paid
          end
        end
      end
    end

  end # Class Methods

end

def valid_attributes
  {
    :cc_type               => 'visa',
    :cc_number             => '4111111111111111',
    :cc_expire_on          => 1.year.from_now.to_date,
    :cc_full_name          => 'John Doe Huber',
    :cc_verification_value => '111'
  }
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

