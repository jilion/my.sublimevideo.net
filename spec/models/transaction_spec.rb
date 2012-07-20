require 'spec_helper'

describe Transaction, :plans do
  before do
    @user = create(:user)
    @user_with_no_cc = create(:user_no_cc)
  end

  context "Factory" do
    subject { @transaction = create(:transaction, invoices: [create(:invoice, amount: 1000, state: 'open')]) }

    its(:user)      { should be_present }
    its(:invoices)  { should be_present }
    its(:order_id)  { should =~ /^[a-z0-9]{30}$/ }
    its(:amount)    { should eq 1000 }
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
      subject { build(:transaction) }

      specify { subject.invoices.should be_empty }
      specify { subject.should_not be_valid }
      specify { subject.should have(1).error_on(:base) }
    end

    describe "#all_invoices_belong_to_same_user" do
      before do
        @site1 = create(:site)
        @site2 = create(:site)
      end
      subject { build(:transaction, invoices: [create(:invoice, site: @site1), create(:invoice, site: @site2)]) }

      specify { subject.should_not be_valid }
      specify { subject.should have(1).error_on(:base) }
    end
  end # Validations

  describe "Callbacks" do
    before do
      @site = create(:site)
      @invoice1 = create(:invoice, site: @site, amount: 200, state: 'open')
      @invoice2 = create(:invoice, site: @site, amount: 300, state: 'paid')
      @invoice3 = create(:invoice, site: @site, amount: 400, state: 'failed')
    end
    subject { build(:transaction, invoices: [@invoice1, @invoice2, @invoice3]) }

    describe "before_create :reject_paid_invoices" do
      it "should reject any paid invoices" do
        subject.invoices.should =~ [@invoice1, @invoice2, @invoice3]
        subject.save!
        subject.reload.invoices.should =~ [@invoice1, @invoice3]
      end
    end

    describe "before_create :set_user_id" do
      it "should set user_id" do
        subject.user.should be_nil
        subject.save!
        subject.reload.user.should eq @invoice1.user
      end
    end

    describe "before_save :set_fields_from_ogone_response" do
      context "with no response from Ogone" do
        it "should not set Ogone specific fields" do
          subject.instance_variable_set(:@ogone_response_info, nil)
          subject.save
          subject.pay_id.should be_nil
          subject.status.should be_nil
          subject.error.should be_nil
        end
      end

      context "with a response from Ogone" do
        it "should set Ogone specific fields" do
          subject.instance_variable_set(:@ogone_response_info, {
            "PAYID" => "123",
            "ACCEPTANCE" => "321",
            "NCSTATUS" => "0",
            "STATUS" => "9",
            "ECI" => "7",
            "NCERROR" => "0",
            "NCERRORPLUS" => "!"
          })
          subject.save
          subject.pay_id.should eq "123"
          subject.nc_status.should eq 0
          subject.status.should eq 9
          subject.error.should eq "!"
        end
      end
    end

    describe "before_create :set_amount" do
      it "should set transaction amount to the sum of all its invoices amount" do
        subject.amount.should be_nil
        subject.save!
        subject.reload.amount.should eq 600
      end
    end
  end # Callbacks

  describe "State Machine" do
    before do
      @site        = create(:site)
      @invoice1    = create(:invoice, site: @site, state: 'open')
      @invoice2    = create(:invoice, site: @site, state: 'failed')
      @transaction = create(:transaction, invoices: [@invoice1, @invoice2])
    end
    subject { @transaction }

    describe "Initial state" do
      it { should be_unprocessed }
    end

    describe "Events" do
      describe "#wait_d3d" do
        before { subject.wait_d3d }

        context "from unprocessed state" do
          subject { @transaction.reload.update_attribute(:state, 'unprocessed'); @transaction }
          it { should be_waiting_d3d }
        end

        context "from waiting_d3d state" do
          subject { @transaction.reload.update_attribute(:state, 'waiting_d3d'); @transaction }
          it { should be_waiting_d3d }
        end

        context "from failed state" do
          subject { @transaction.reload.update_attribute(:state, 'failed'); @transaction }
          it { should be_failed }
        end

        context "from paid state" do
          subject { @transaction.reload.update_attribute(:state, 'paid'); @transaction }
          it { should be_paid }
        end
      end

      describe "#succeed" do
        before { subject.succeed }

        context "from unprocessed state" do
          subject { @transaction.reload.update_attribute(:state, 'unprocessed'); @transaction }
          it { should be_paid }
        end

        context "from waiting_d3d state" do
          subject { @transaction.reload.update_attribute(:state, 'waiting_d3d'); @transaction }
          it { should be_paid }
        end

        context "from failed state" do
          subject { @transaction.reload.update_attribute(:state, 'failed'); @transaction }
          it { should be_failed }
        end

        context "from paid state" do
          subject { @transaction.reload.update_attribute(:state, 'paid'); @transaction }
          it { should be_paid }
        end
      end

      describe "#fail" do
        before { subject.fail }

        context "from unprocessed state" do
          subject { @transaction.reload.update_attribute(:state, 'unprocessed'); @transaction }
          it { should be_failed }
        end

        context "from waiting_d3d state" do
          subject { @transaction.reload.update_attribute(:state, 'waiting_d3d'); @transaction }
          it { should be_failed }
        end

        context "from failed state" do
          subject { @transaction.reload.update_attribute(:state, 'failed'); @transaction }
          it { should be_failed }
        end

        context "from paid state" do
          subject { @transaction.reload.update_attribute(:state, 'paid'); @transaction }
          it { should be_paid }
        end
      end
    end # Events

    describe "Transitions" do
      describe "after_transition on: [:succeed, :fail], do: :update_invoices" do
        describe "initial invoices state" do
          specify do
            @invoice1.should be_open
            @invoice1.paid_at.should be_nil
            @invoice1.last_failed_at.should be_nil
            @invoice2.should be_failed
            @invoice2.paid_at.should be_nil
            @invoice2.last_failed_at.should be_nil
          end
        end

        describe "on :succeed" do
          before { subject.reload.succeed }

          specify do
            @invoice1.reload.should be_paid
            @invoice1.paid_at.to_i.should be_within(10).of(subject.updated_at.to_i)
            @invoice1.last_failed_at.should be_nil
            @invoice2.reload.should be_paid
            @invoice2.paid_at.to_i.should be_within(10).of(subject.updated_at.to_i)
            @invoice2.last_failed_at.should be_nil
          end
        end

        describe "on :fail" do
          before { subject.reload.fail }

          specify do
            @invoice1.reload.should be_failed
            @invoice1.paid_at.should be_nil
            @invoice1.last_failed_at.to_i.should be_within(10).of(subject.updated_at.to_i)
            @invoice2.reload.should be_failed
            @invoice2.paid_at.should be_nil
            @invoice2.last_failed_at.to_i.should be_within(10).of(subject.updated_at.to_i)
          end
        end
      end

      describe "after_transition on: :succeed, do: :send_charging_succeeded_email" do
        context "from open" do
          subject { create(:transaction, invoices: [create(:invoice)]) }

          it "should send an email to invoice.user" do
            subject
            expect { subject.succeed }.to change(Delayed::Job.where { handler =~ '%Class%transaction_succeeded%' }, :count).by(1)
          end
        end
      end

      describe "after_transition on: :fail, do: :send_charging_failed_email" do
        context "from open" do
          subject { create(:transaction, invoices: [create(:invoice)]) }

          it "should send an email to invoice.user" do
            subject
            expect { subject.fail }.to change(Delayed::Job.where { handler =~ '%Class%transaction_failed%' }, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should eq [subject.user.email]
          end
        end
      end
    end # Transitions

  end # State Machine

  describe "Scopes" do
    before do
      @site                    = create(:fake_site)
      @invoice                 = create(:invoice, site: @site, state: 'open')
      @unprocessed_transaction = create(:transaction, invoices: [@invoice])
      @failed_transaction      = create(:transaction, invoices: [@invoice], state: 'failed')
      @paid_transaction        = create(:transaction, invoices: [@invoice], state: 'paid')
    end

    describe "#failed" do
      specify { Transaction.failed.all.should =~ [@failed_transaction] }
    end
  end # Scopes

  describe "Class Methods" do

    describe ".charge_invoices" do
      before do
        Invoice.delete_all
        @user1    = create(:user)
        @user2    = create(:user, state: 'suspended')
        @site1    = create(:site, user: @user1)
        @site2    = create(:site, user: @user2)
        @invoice1 = create(:invoice, state: 'open', site: @site1, renew: true)
        @invoice2 = create(:invoice, state: 'open', site: @site1, renew: false)
        @invoice3 = create(:invoice, state: 'failed', site: @site1)
        @invoice4 = create(:invoice, state: 'failed', site: @site2)
        @invoice5 = create(:invoice, state: 'paid', site: @site1)
      end
      before { Delayed::Job.delete_all }

      it "should delay invoice charging for open invoices which have the renew flag == true by user" do
        Delayed::Job.where(:handler.matches => "%charge_invoices_by_user_id%").should be_empty
        expect { Transaction.charge_invoices }.to change(Delayed::Job.where(:handler.matches => "%charge_invoices_by_user_id%"), :count).by(1)
        djs = Delayed::Job.where(:handler.matches => "%charge_invoices_by_user_id%")
        djs.should have(1).item
        djs.map { |dj| YAML.load(dj.handler).args[0] }.should =~ [@invoice1.reload.site.user.id]
      end
    end # .charge_invoices

    describe ".charge_invoices_by_user_id" do
      use_vcr_cassette "ogone/visa_payment_generic"
      before do
        Invoice.delete_all
        @user1    = create(:user)
        @user2    = create(:user)
        @site1    = create(:site, user: @user1, first_paid_plan_started_at: Time.now.utc)
        @site2    = create(:site, user: @user2).tap { |s| s.update_column(:first_paid_plan_started_at, nil) }
        @site1.invoices.delete_all
        @site2.invoices.delete_all
        @invoice1 = create(:invoice, site: @site1, state: 'paid', renew: false) # first invoice
        @invoice2 = create(:invoice, site: @site1, state: 'failed', renew: true)
        @invoice3 = create(:invoice, site: @site1, state: 'open', renew: true)
        @invoice4 = create(:invoice, site: @site2, state: 'failed', renew: false) # first invoice
      end
      before do
        @user1.reload
        @user2.reload
        Delayed::Job.delete_all
      end

      it "should delay invoice charging for open invoices which have the renew flag == true" do
        @invoice1.reload.should be_paid
        @invoice2.reload.should be_failed
        @invoice3.reload.should be_open
        Transaction.should_receive(:charge_by_invoice_ids).with([@invoice2.id, @invoice3.id]).and_return(an_instance_of(Transaction))
        Transaction.charge_invoices_by_user_id(@user1.id)
      end

      it "should charge invoices" do
        @invoice1.reload.should be_paid
        @invoice2.reload.should be_failed
        @invoice3.reload.should be_open
        Transaction.charge_invoices_by_user_id(@user1.id)
        @invoice1.reload.should be_paid
        @invoice2.reload.should be_paid
        @invoice3.reload.should be_paid
      end

      context "invoice with 15 failed transactions or more" do
        it "doesn't try to charge the invoice" do
          @invoice2.reload
          15.times { create(:transaction, invoices: [@invoice2], state: 'failed') }
          Transaction.should_not_receive(:charge_by_invoice_ids)
          Transaction.charge_invoices_by_user_id(@user1.id)
          @invoice2.reload.should be_failed
        end

        it "doesn't try to charge at all if it's the only invoice" do
          @invoice4.reload
          15.times { create(:transaction, invoices: [@invoice4], state: 'failed') }
          Transaction.should_not_receive(:charge_by_invoice_ids)
          Transaction.charge_invoices_by_user_id(@user2.id)
        end

        context "invoice is not the first one" do
          context "user is not a vip" do
            it "suspend the user" do
              @invoice2.reload
              15.times { create(:transaction, invoices: [@invoice2], state: 'failed') }
              Transaction.should_not_receive(:charge_by_invoice_ids)
              Transaction.charge_invoices_by_user_id(@user1.id)
              @invoice2.reload.should be_failed
              @user1.reload.should be_suspended
            end
          end

          context "user is a vip" do
            before do
              @user1.update_attribute(:vip, true)
            end

            it "doesn't suspend the user" do
              @invoice2.reload
              15.times { create(:transaction, invoices: [@invoice2], state: 'failed') }
              Transaction.should_not_receive(:charge_by_invoice_ids)
              Transaction.charge_invoices_by_user_id(@user1.id)
              @invoice2.reload.should be_failed
              @user1.reload.should be_active
            end
          end
        end

        context "invoice is the first one" do
          it "cancels the invoice" do
            @invoice4.reload
            15.times { create(:transaction, invoices: [@invoice4], state: 'failed') }
            Transaction.charge_invoices_by_user_id(@user2.id)
            @invoice4.reload.should be_canceled
          end

          it "sends an email to the user" do
            @invoice4.reload
            15.times { create(:transaction, invoices: [@invoice4], state: 'failed') }

            expect { Transaction.charge_invoices_by_user_id(@user2.id) }.to change(Delayed::Job.where { handler =~ '%Class%too_many_charging_attempts%' }, :count).by(1)
          end
        end
      end
    end # .charge_invoices_by_user_id

    describe ".charge_by_invoice_ids" do
      context "with a credit card alias" do
        use_vcr_cassette "ogone/visa_payment_2000_alias"

        before do
          @user.reload
          @invoice1 = create(:invoice, site: create(:site, user: @user), state: 'open')
          @invoice2 = create(:invoice, site: create(:site, user: @user), state: 'failed')
          @invoice3 = create(:invoice, site: create(:site, user: @user), state: 'paid')
        end

        it "charges Ogone for the total amount of the open and failed invoices" do
          Ogone.should_receive(:purchase).with(@invoice1.amount + @invoice2.amount, @user.cc_alias, {
            order_id: an_instance_of(String),
            description: an_instance_of(String),
            email: @user.email,
            billing_address: {
              address1: @user.billing_address_1,
              zip: @user.billing_postal_code,
              city: @user.billing_city,
              country: @user.billing_country
            },
            paramplus: "PAYMENT=TRUE"
          })
          Transaction.charge_by_invoice_ids([@invoice1.id, @invoice2.id, @invoice3.id])
        end

        it "stores cc info from the user's cc info" do
          Transaction.charge_by_invoice_ids([@invoice1.id, @invoice2.id, @invoice3.id])

          @invoice1.last_transaction.cc_type.should        eq @user.cc_type
          @invoice1.last_transaction.cc_last_digits.should eq @user.cc_last_digits
          @invoice1.last_transaction.cc_expire_on.should   eq @user.cc_expire_on
        end
      end

      context "with a succeeding purchase" do
        before do
          @user.reload
          @invoice1 = create(:invoice, site: create(:site, user: @user), state: 'open')
        end

        context "credit card" do
          use_vcr_cassette "ogone/visa_payment_2000_credit_card"

          it "sets transaction and invoices to paid state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card }).should be_true
            @invoice1.last_transaction.should be_paid
            @invoice1.reload.should be_paid
          end
        end

        context "alias" do
          use_vcr_cassette "ogone/visa_payment_2000_alias"

          it "sets transaction and invoices to paid state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id]).should be_true
            @invoice1.last_transaction.should be_paid
            @invoice1.reload.should be_paid
          end
        end

        context "with a purchase that need a 3d secure authentication" do
          before do
            Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "5", "STATUS" => "46", "NCERRORPLUS" => "!" }) }
          end

          context "alias" do
            it "should set transaction and invoices to waiting_d3d state" do
              @invoice1.should be_open
              Transaction.charge_by_invoice_ids([@invoice1.id]).should be_true
              @invoice1.last_transaction.should be_failed
              @invoice1.last_transaction.error.should eq "!"
              @invoice1.reload.should be_failed
            end
          end
        end
      end

      context "with a failing purchase" do
        before do
          @invoice1 = create(:invoice, site: create(:site, user: @user), state: 'open')
        end

        context "with a purchase that raise an error" do
          before { Ogone.stub(:purchase).and_raise("Purchase error!") }
          it "should set transaction and invoices to failed state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.last_transaction.should be_failed
            @invoice1.last_transaction.error.should eq "Purchase error!"
            @invoice1.reload.should be_failed
          end
        end

        context "with a failing purchase due to an invalid credit card" do
          before { Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "5", "STATUS" => "0", "NCERRORPLUS" => "invalid" }) } }
          it "should set transaction and invoices to failed state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.last_transaction.should be_failed
            @invoice1.reload.should be_failed
          end
        end

        context "with a failing purchase due to a refused purchase" do
          before { Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "3", "STATUS" => "93", "NCERRORPLUS" => "refused" }) } }
          it "should set transaction and invoices to failed state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.reload.should be_failed
          end
        end

        context "with a failing purchase due to a waiting authorization" do
          before { Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "0", "STATUS" => "51", "NCERRORPLUS" => "waiting" }) } }
          it "should not succeed nor fail transaction nor invoices" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.last_transaction.should be_waiting
            @invoice1.reload.should be_waiting
          end
        end

        context "with a failing purchase due to a uncertain result" do
          before { Ogone.stub(:purchase) { mock('response', params: { "NCSTATUS" => "2", "STATUS" => "92", "NCERRORPLUS" => "unknown" }) } }
          it "should not succeed nor fail transaction nor invoices, with status 2" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.last_transaction.should be_waiting
            @invoice1.reload.should be_waiting
          end
        end

      end

    end # .charge_by_invoice_ids

  end # Class Methods

  describe "Instance Methods" do

    describe "#process_payment_response" do
      before do
        @user.reload
        @site1    = create(:site, user: @user, plan_id: @free_plan.id)
        @site2    = create(:site, user: @user, plan_id: @paid_plan.id)
        @invoice1 = create(:invoice, site: @site1, state: 'open')
        @invoice2 = create(:invoice, site: @site2, state: 'failed')
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
      subject { create(:transaction, invoices: [@invoice1.reload, @invoice2.reload]) }

      context "STATUS is 9" do
        it "puts transaction in 'paid' state" do
          subject.should be_unprocessed

          subject.process_payment_response(@success_params)

          subject.reload.should   be_paid
          @invoice1.reload.should be_paid
          @invoice2.reload.should be_paid
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
          @invoice1.reload.should  be_waiting
          @invoice2.reload.should  be_waiting
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
          @invoice1.reload.should  be_failed
          @invoice2.reload.should  be_failed
        end
      end

      context "STATUS is 46" do
        it "puts transaction in 'failed' state" do
          subject.should be_unprocessed
          subject.error.should be_nil

          subject.process_payment_response(@d3d_params)

          subject.reload.should   be_failed
          subject.error.should    eq "!"
          @invoice1.reload.should be_failed
          @invoice2.reload.should be_failed
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

          @invoice1.reload.should be_failed
          @invoice2.reload.should be_failed
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

          @invoice1.reload.should be_waiting
          @invoice2.reload.should be_waiting
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

          @invoice1.reload.should be_waiting
          @invoice2.reload.should be_waiting

          subject.process_payment_response(@success_params)

          subject.reload.should    be_paid
          subject.nc_status.should eq 0
          subject.status.should    eq 9
          subject.error.should     eq "!"

          @invoice1.reload.should be_paid
          @invoice2.reload.should be_paid
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

          @invoice1.reload.should be_waiting
          @invoice2.reload.should be_waiting

          subject.process_payment_response(@success_params)

          subject.reload.should be_paid
          subject.nc_status.should eq 0
          subject.status.should    eq 9
          subject.error.should     eq "!"

          @invoice1.reload.should be_paid
          @invoice2.reload.should be_paid
        end
      end
    end

    describe "#description" do
      before do
        @site1    = create(:site, user: @user, plan_id: @free_plan.id)
        @site2    = create(:site, user: @user, plan_id: @paid_plan.id)
        @invoice1 = create(:invoice, site: @site1, state: 'open')
        @invoice2 = create(:invoice, site: @site2, state: 'failed')
      end
      subject { create(:transaction, invoices: [@invoice1.reload, @invoice2.reload]) }

      it "should create a description with invoices references" do
        subject.description.should eq "SublimeVideo Invoices: ##{@invoice1.reference}, ##{@invoice2.reference}"
      end
    end

  end

end

# == Schema Information
#
# Table name: transactions
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  order_id       :string(255)
#  state          :string(255)
#  amount         :integer
#  error          :text
#  cc_type        :string(255)
#  cc_last_digits :string(255)
#  cc_expire_on   :date
#  pay_id         :string(255)
#  nc_status      :integer
#  status         :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_transactions_on_order_id  (order_id) UNIQUE
#

