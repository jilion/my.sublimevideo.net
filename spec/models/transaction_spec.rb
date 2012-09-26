require 'spec_helper'

describe Transaction do
  let(:user)            { create(:user) }
  let(:site1)           { create(:site, user: user) }
  let(:site2)           { create(:site, user: user) }
  let(:open_invoice)    { create(:invoice, site: site1, state: 'open') }
  let(:failed_invoice)  { create(:invoice, site: site2, state: 'failed') }
  let(:paid_invoice)    { create(:invoice, site: site2, state: 'paid') }
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
      context "with no response from Ogone" do
        it "should not set Ogone specific fields" do
          new_transaction.instance_variable_set(:@ogone_response_info, nil)

          new_transaction.save!

          new_transaction.pay_id.should be_nil
          new_transaction.status.should be_nil
          new_transaction.error.should  be_nil
        end
      end

      context "with a response from Ogone" do
        it "should set Ogone specific fields" do
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
          before { transaction.succeed }

          specify do
            open_invoice.reload.should be_paid
            open_invoice.paid_at.to_i.should be_within(10).of(transaction.updated_at.to_i)
            open_invoice.last_failed_at.should be_nil

            failed_invoice.reload.should be_paid
            failed_invoice.paid_at.to_i.should be_within(10).of(transaction.updated_at.to_i)
            failed_invoice.last_failed_at.should be_nil
          end
        end

        describe "on :fail" do
          before { transaction.fail }

          specify do
            open_invoice.reload.should be_failed
            open_invoice.paid_at.should be_nil
            open_invoice.last_failed_at.to_i.should be_within(10).of(transaction.updated_at.to_i)

            failed_invoice.reload.should be_failed
            failed_invoice.paid_at.should be_nil
            failed_invoice.last_failed_at.to_i.should be_within(10).of(transaction.updated_at.to_i)
          end
        end
      end

      describe "after_transition on: :succeed, do: :send_charging_succeeded_email" do
        context "from open" do
          it "should send an email to invoice.user" do
            transaction
            -> { transaction.succeed }.should delay('%Class%transaction_succeeded%')
          end
        end
      end

      describe "after_transition on: :fail, do: :send_charging_failed_email" do
        context "from open" do
          it "should send an email to invoice.user" do
            transaction
            -> { transaction.fail }.should delay('%Class%transaction_failed%')
            ActionMailer::Base.deliveries.last.to.should eq [user.email]
            ActionMailer::Base.deliveries.last.to.should eq [transaction.user.email]
          end
        end
      end
    end # Transitions

  end # State Machine

  describe "Scopes" do
    before do
      create(:transaction, invoices: [open_invoice])
      @failed_transaction = create(:transaction, invoices: [open_invoice], state: 'failed')
      create(:transaction, invoices: [open_invoice], state: 'paid')
    end

    describe "#failed" do
      specify { Transaction.failed.all.should =~ [@failed_transaction] }
    end
  end # Scopes

  describe "Class Methods" do

    describe ".charge_invoices" do
      let(:suspended_user) { create(:user, state: 'suspended') }
      before do
        @site3    = create(:site, user: suspended_user)
        @invoice1 = create(:invoice, state: 'open', site: site1, renew: true)
        @invoice2 = create(:invoice, state: 'open', site: @site3, renew: false)
        @invoice3 = create(:invoice, state: 'failed', site: site1)
        @invoice4 = create(:invoice, state: 'failed', site: @site3)
        @invoice5 = create(:invoice, state: 'paid', site: site1)
      end
      # before { Delayed::Job.delete_all }

      it "should delay invoice charging for open invoices which have the renew flag == true by user" do
        -> { Transaction.charge_invoices }.should delay('%charge_invoices_by_user_id%')
        djs = Delayed::Job.where{ handler =~ "%charge_invoices_by_user_id%" }
        djs.should have(1).item
        djs.map { |dj| YAML.load(dj.handler).args[0] }.should =~ [@invoice1.reload.site.user.id]
      end
    end # .charge_invoices

    describe ".charge_invoices_by_user_id" do
      use_vcr_cassette "ogone/visa_payment_generic"
      before do
        user2    = create(:user)
        site3    = create(:site, user: user2)
        @invoice1 = create(:invoice, site: site1, state: 'paid', renew: false) # first invoice
        @invoice2 = create(:invoice, site: site1, state: 'failed', renew: true)
        @invoice3 = create(:invoice, site: site1, state: 'open', renew: true)
        @invoice4 = create(:invoice, site: site3, state: 'open', renew: true)
      end

      it "should delay invoice charging for open invoices which have the renew flag == true" do
        @invoice1.reload.should be_paid
        @invoice2.reload.should be_failed
        @invoice3.reload.should be_open
        Transaction.should_receive(:charge_by_invoice_ids).with([@invoice2.id, @invoice3.id]).and_return(an_instance_of(Transaction))

        Transaction.charge_invoices_by_user_id(user.id)
      end

      it "should charge invoices" do
        @invoice1.reload.should be_paid
        @invoice2.reload.should be_failed
        @invoice3.reload.should be_open

        Transaction.charge_invoices_by_user_id(user.id)

        @invoice1.reload.should be_paid
        @invoice2.reload.should be_paid
        @invoice3.reload.should be_paid
      end

      context "invoice with 15 failed transactions or more" do
        it "doesn't try to charge the invoice" do
          15.times { create(:transaction, invoices: [@invoice2], state: 'failed') }
          Transaction.should_not_receive(:charge_by_invoice_ids)

          Transaction.charge_invoices_by_user_id(user.id)

          @invoice2.reload.should be_failed
        end

        context "invoice is not the first one" do
          context "user is not a vip" do
            it "suspend the user" do
              15.times { create(:transaction, invoices: [@invoice2], state: 'failed') }
              Transaction.should_not_receive(:charge_by_invoice_ids)

              Transaction.charge_invoices_by_user_id(user.id)

              @invoice2.reload.should be_failed
              user.reload.should be_suspended
            end
          end

          context "user is a vip" do
            before do
              user.update_attribute(:vip, true)
            end

            it "doesn't suspend the user" do
              15.times { create(:transaction, invoices: [@invoice2], state: 'failed') }
              Transaction.should_not_receive(:charge_by_invoice_ids)

              Transaction.charge_invoices_by_user_id(user.id)

              @invoice2.reload.should be_failed
              user.reload.should be_active
            end
          end
        end
      end
    end # .charge_invoices_by_user_id

    describe ".charge_by_invoice_ids" do
      context "with a credit card alias" do
        use_vcr_cassette "ogone/visa_payment_2000_alias"

        it "charges Ogone for the total amount of the open and failed invoices" do
          Ogone.should_receive(:purchase).with(open_invoice.amount + failed_invoice.amount, user.cc_alias, {
            order_id: an_instance_of(String),
            description: an_instance_of(String),
            email: user.email,
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

          open_invoice.last_transaction.cc_type.should        eq user.cc_type
          open_invoice.last_transaction.cc_last_digits.should eq user.cc_last_digits
          open_invoice.last_transaction.cc_expire_on.should   eq user.cc_expire_on
        end
      end

      context "with a succeeding purchase" do
        context "credit card" do
          use_vcr_cassette "ogone/visa_payment_2000_credit_card"

          it "sets transaction and invoices to paid state" do
            open_invoice.should be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card }).should be_true
            open_invoice.last_transaction.should be_paid
            open_invoice.reload.should be_paid
          end
        end

        context "alias" do
          use_vcr_cassette "ogone/visa_payment_2000_alias"

          it "sets transaction and invoices to paid state" do
            open_invoice.should be_open
            Transaction.charge_by_invoice_ids([open_invoice.id]).should be_true
            open_invoice.last_transaction.should be_paid
            open_invoice.reload.should be_paid
          end
        end

        context "with a purchase that need a 3d secure authentication" do
          before do
            Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "5", "STATUS" => "46", "NCERRORPLUS" => "!" }) }
          end

          context "alias" do
            it "should set transaction and invoices to waiting_d3d state" do
              open_invoice.should be_open
              Transaction.charge_by_invoice_ids([open_invoice.id]).should be_true
              open_invoice.last_transaction.should be_failed
              open_invoice.last_transaction.error.should eq "!"
              open_invoice.reload.should be_failed
            end
          end
        end
      end

      context "with a failing purchase" do
        context "with a purchase that raise an error" do
          before { Ogone.stub(:purchase).and_raise("Purchase error!") }
          it "should set transaction and invoices to failed state" do
            open_invoice.should be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            open_invoice.last_transaction.should be_failed
            open_invoice.last_transaction.error.should eq "Purchase error!"
            open_invoice.reload.should be_failed
          end
        end

        context "with a failing purchase due to an invalid credit card" do
          before { Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "5", "STATUS" => "0", "NCERRORPLUS" => "invalid" }) } }
          it "should set transaction and invoices to failed state" do
            open_invoice.should be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            open_invoice.last_transaction.should be_failed
            open_invoice.reload.should be_failed
          end
        end

        context "with a failing purchase due to a refused purchase" do
          before { Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "3", "STATUS" => "93", "NCERRORPLUS" => "refused" }) } }
          it "should set transaction and invoices to failed state" do
            open_invoice.should be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            open_invoice.reload.should be_failed
          end
        end

        context "with a failing purchase due to a waiting authorization" do
          before { Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "0", "STATUS" => "51", "NCERRORPLUS" => "waiting" }) } }
          it "should not succeed nor fail transaction nor invoices" do
            open_invoice.should be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            open_invoice.last_transaction.should be_waiting
            open_invoice.reload.should be_waiting
          end
        end

        context "with a failing purchase due to a uncertain result" do
          before { Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "2", "STATUS" => "92", "NCERRORPLUS" => "unknown" }) } }
          it "should not succeed nor fail transaction nor invoices, with status 2" do
            open_invoice.should be_open
            Transaction.charge_by_invoice_ids([open_invoice.id], { credit_card: user.credit_card })
            open_invoice.last_transaction.should be_waiting
            open_invoice.reload.should be_waiting
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
          subject.should be_unprocessed

          subject.process_payment_response(@success_params)

          subject.reload.should   be_paid
          open_invoice.reload.should be_paid
          failed_invoice.reload.should be_paid
        end
      end

      context "STATUS is 51" do
        it "puts transaction in 'waiting' state" do
          subject.should be_unprocessed

          subject.process_payment_response(@waiting_params)

          subject.reload.should    be_waiting
          subject.nc_status.should eq 0
          subject.status.should    eq 51
          subject.error.should     eq "waiting"
          open_invoice.reload.should  be_waiting
          failed_invoice.reload.should  be_waiting
        end
      end

      context "STATUS is 0" do
        it "puts transaction in 'failed' state" do
          subject.should be_unprocessed

          subject.process_payment_response(@invalid_params)

          subject.reload.should    be_failed
          subject.nc_status.should eq 5
          subject.status.should    eq 0
          subject.error.should     eq "invalid"
          open_invoice.reload.should  be_failed
          failed_invoice.reload.should  be_failed
        end
      end

      context "STATUS is 46" do
        it "puts transaction in 'failed' state" do
          subject.should be_unprocessed
          subject.error.should be_nil

          subject.process_payment_response(@d3d_params)

          subject.reload.should   be_failed
          subject.error.should    eq "!"
          open_invoice.reload.should be_failed
          failed_invoice.reload.should be_failed
        end
      end

      context "STATUS is 93" do
        it "puts transaction in 'failed' state" do
          subject.should be_unprocessed

          subject.process_payment_response(@refused_params)

          subject.reload.should    be_failed
          subject.nc_status.should eq 3
          subject.status.should    eq 93
          subject.error.should     eq "refused"

          open_invoice.reload.should be_failed
          failed_invoice.reload.should be_failed
        end
      end

      context "STATUS is 92" do
        it "puts transaction in 'waiting' state" do
          subject.should be_unprocessed
          Notify.should_receive(:send)

          subject.process_payment_response(@unknown_params)

          subject.reload.should    be_waiting
          subject.nc_status.should eq 2
          subject.status.should    eq 92
          subject.error.should     eq "unknown"

          open_invoice.reload.should be_waiting
          failed_invoice.reload.should be_waiting
        end
      end

      context "first STATUS is 51, second is 9" do
        it "puts transaction in 'waiting' state, and then puts it in 'paid' state" do
          subject.should be_unprocessed

          subject.process_payment_response(@waiting_params)

          subject.reload.should    be_waiting
          subject.nc_status.should eq 0
          subject.status.should    eq 51
          subject.error.should     eq "waiting"
          subject.should be_waiting

          open_invoice.reload.should be_waiting
          failed_invoice.reload.should be_waiting

          subject.process_payment_response(@success_params)

          subject.reload.should    be_paid
          subject.nc_status.should eq 0
          subject.status.should    eq 9
          subject.error.should     eq "!"

          open_invoice.reload.should be_paid
          failed_invoice.reload.should be_paid
        end
      end

      context "first STATUS is 92, second is 9" do
        it "puts transaction in 'waiting' state, and then puts it in 'paid' state" do
          subject.should be_unprocessed
          Notify.should_receive(:send)

          subject.process_payment_response(@unknown_params)

          subject.reload.should    be_waiting
          subject.nc_status.should eq 2
          subject.status.should    eq 92
          subject.error.should     eq "unknown"

          open_invoice.reload.should be_waiting
          failed_invoice.reload.should be_waiting

          subject.process_payment_response(@success_params)

          subject.reload.should be_paid
          subject.nc_status.should eq 0
          subject.status.should    eq 9
          subject.error.should     eq "!"

          open_invoice.reload.should be_paid
          failed_invoice.reload.should be_paid
        end
      end
    end

    describe "#description" do
      subject { create(:transaction, invoices: [open_invoice, failed_invoice]) }

      it "should create a description with invoices references" do
        subject.description.should eq "SublimeVideo Invoices: ##{open_invoice.reference}, ##{failed_invoice.reference}"
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
#  created_at     :datetime         not null
#  error          :text
#  id             :integer          not null, primary key
#  nc_status      :integer
#  order_id       :string(255)
#  pay_id         :string(255)
#  state          :string(255)
#  status         :integer
#  updated_at     :datetime         not null
#  user_id        :integer
#
# Indexes
#
#  index_transactions_on_order_id  (order_id) UNIQUE
#

