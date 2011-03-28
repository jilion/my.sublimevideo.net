require 'spec_helper'

describe Transaction do
  before(:all) do
    @user = Factory(:user)
    @user_with_no_cc = Factory(:user_no_cc)
  end

  context "Factory" do
    before(:all) { @transaction = Factory(:transaction, invoices: [Factory(:invoice, amount: 1000, state: 'open')]) }
    subject { @transaction }

    its(:user)      { should be_present }
    its(:invoices)  { should be_present }
    its(:order_id)  { should =~ /^[a-z0-9]{30}$/ }
    its(:amount)    { should == 1000 }
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
      @invoice1 = Factory(:invoice, site: @site, amount: 200, state: 'open')
      @invoice2 = Factory(:invoice, site: @site, amount: 300, state: 'paid')
      @invoice3 = Factory(:invoice, site: @site, amount: 400, state: 'failed')
    end
    subject { Factory.build(:transaction, invoices: [@invoice1, @invoice2, @invoice3]) }

    describe "before_create :reject_paid_invoices" do
      it "should reject any paid invoices" do
        subject.invoices.should == [@invoice1, @invoice2, @invoice3]
        subject.save!
        subject.reload.invoices.should == [@invoice1, @invoice3]
      end
    end

    describe "before_create :set_user_id" do
      it "should set user_id" do
        subject.user.should be_nil
        subject.save!
        subject.reload.user.should == @invoice1.user
      end
    end

    describe "before_save :set_fields_from_ogone_response" do
      context "with no response from Ogone" do
        it "should not set Ogone specific fields" do
          subject.instance_variable_set(:@ogone_response_infos, nil)
          subject.save
          subject.pay_id.should be_nil
          subject.status.should be_nil
          subject.error.should be_nil
        end
      end

      context "with a response from Ogone" do
        it "should set Ogone specific fields" do
          subject.instance_variable_set(:@ogone_response_infos, {
            "PAYID" => "123",
            "ACCEPTANCE" => "321",
            "NCSTATUS" => "0",
            "STATUS" => "9",
            "ECI" => "7",
            "NCERROR" => "0",
            "NCERRORPLUS" => "!"
          })
          subject.save
          subject.pay_id.should == "123"
          subject.nc_status.should == 0
          subject.status.should == 9
          subject.error.should == "!"
        end
      end
    end

    describe "before_create :set_amount" do
      it "should set transaction amount to the sum of all its invoices amount" do
        subject.amount.should be_nil
        subject.save!
        subject.reload.amount.should == 600
      end
    end
  end # Callbacks

  describe "State Machine" do
    before(:all) do
      @site        = Factory(:site)
      @invoice1    = Factory(:invoice, site: @site, state: 'open')
      @invoice2    = Factory(:invoice, site: @site, state: 'failed')
      @transaction = Factory(:transaction, invoices: [@invoice1, @invoice2])
    end
    subject { @transaction }

    describe "Initial state" do
      it { should be_unprocessed }
    end

    describe "Events" do
      describe "#wait_d3d" do
        before(:each) { subject.wait_d3d }

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
        before(:each) { subject.succeed }

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
        before(:each) { subject.fail }

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
      describe "after_transition :on => [:succeed, :fail], :do => :update_invoices" do
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
          before(:each) { subject.reload.succeed }

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
          before(:each) { subject.reload.fail }

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

      describe "after_transition :on => :succeed, :do => :send_charging_succeeded_email", focus: true do
        context "from open" do
          subject { Factory(:transaction, invoices: [Factory(:invoice)]) }

          it "should send an email to invoice.user" do
            subject
            lambda { subject.succeed }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.user.email]
          end
        end
      end

      describe "after_transition :on => :fail, :do => :send_charging_failed_email" do
        context "from open" do
          subject { Factory(:transaction, invoices: [Factory(:invoice)]) }

          it "should send an email to invoice.user" do
            subject
            lambda { subject.fail }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.user.email]
          end
        end
      end
    end # Transitions

  end # State Machine

  describe "Scopes" do
    before(:all) do
      @site                    = Factory(:site)
      @invoice                 = Factory(:invoice, site: @site, state: 'open')
      @transaction_unprocessed = Factory(:transaction, invoices: [@invoice])
      @transaction_failed      = Factory(:transaction, invoices: [@invoice], state: 'failed')
      @transaction_paid        = Factory(:transaction, invoices: [@invoice], state: 'paid')
    end

    describe "#failed" do
      specify { Transaction.failed.all.should =~ [@transaction_failed] }
    end
  end # Scopes

  describe "Class Methods" do

    describe ".charge_all_open_and_failed_invoices" do
      before(:all) do
        Invoice.delete_all
        @user1 = Factory(:user)
        @user2 = Factory(:user)
        @user3 = Factory(:user)
        @site1 = Factory(:site, user: @user1)
        @site2 = Factory(:site, user: @user2)
        @site3 = Factory(:site, user: @user3)
        @invoice1 = Factory(:invoice, state: 'open', site: @site1)
        @invoice2 = Factory(:invoice, state: 'failed', site: @site2)
        @invoice3 = Factory(:invoice, state: 'paid', site: @site3)
      end
      before(:each) do
        Delayed::Job.delete_all
      end

      it "should delay invoice charging for open and failed invoices by user" do
        expect { Transaction.charge_all_open_and_failed_invoices }.to change(Delayed::Job.where(:handler.matches => "%charge_open_and_failed_invoices_by_user_id%"), :count).by(2)
        djs = Delayed::Job.where(:handler.matches => "%charge_open_and_failed_invoices_by_user_id%")
        djs.count.should == 2
        djs.map { |dj| YAML.load(dj.handler)['args'][0] }.should =~ [@invoice1.reload.site.user.id, @invoice2.reload.site.user.id]

        @invoice1.should be_open
        @invoice2.should be_failed
      end

      it "should delay charge_open_and_failed_invoices for the day after" do
        Transaction.charge_all_open_and_failed_invoices
        djs = Delayed::Job.where(:handler.matches => "%charge_all_open_and_failed_invoices%")
        djs.count.should == 1
        djs.first.run_at.to_i.should == Time.now.utc.tomorrow.change(:hour => 1).to_i
      end
    end # .charge_all_open_and_failed_invoices

    describe ".charge_open_and_failed_invoices_by_user_id" do
      use_vcr_cassette "ogone/visa_payment_2000_alias"
      before(:all) do
        Invoice.delete_all
        @invoice1 = Factory(:invoice, state: 'open')
        @invoice2 = Factory(:invoice, state: 'failed')
      end

      it "should delay invoice charging for open and failed invoices" do
        @invoice1.reload.should be_open
        Transaction.should_receive(:charge_by_invoice_ids).with(@invoice1.user.invoices.open_or_failed.map(&:id)).and_return(an_instance_of(Transaction))
        Transaction.charge_open_and_failed_invoices_by_user_id(@invoice1.site.user.id)
      end
    end # .charge_open_and_failed_invoices_of_user

    describe ".charge_by_invoice_ids" do
      context "with a new credit card given through options[:credit_card]" do
        before(:each) do
          @user = Factory(:user_no_cc)
          @user = User.find(@user.id) # to clear the memoized credit card
          
          @site1 = Factory.build(:new_site, user: @user)
          @site1.user.attributes = valid_cc_attributes
          @credit_card = @site1.user.credit_card
          @site1.charging_options = { credit_card: @credit_card }
          @site1.save_without_password_validation # fake sites_controller
          
          @user.pending_cc_type.should == 'visa'
          @user.pending_cc_last_digits.should == '1111'
          @user.pending_cc_expire_on.should == 1.year.from_now.end_of_month.to_date
          @user.cc_type.should be_nil
          @user.cc_last_digits.should be_nil
          @user.cc_expire_on.should be_nil
          
          @invoice1 = Factory(:invoice, site: @site1, state: 'open')
        end

        it "should charge Ogone for the total amount of the open and failed invoices" do
          Ogone.should_receive(:purchase).with(@invoice1.amount, @site1.charging_options[:credit_card], {
            order_id: an_instance_of(String),
            description: an_instance_of(String),
            store: @user.cc_alias,
            email: @user.email,
            billing_address: { zip: @user.postal_code, country: Country[@user.country].name },
            d3d: true,
            paramplus: "PAYMENT=TRUE"
          })
          Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @credit_card })
        end

        it "should not reset the user's credit card infos" do
          VCR.use_cassette("ogone/visa_payment_2000_credit_card") do
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @credit_card }).should be_true
          end
          
          @user.reload
          @user.pending_cc_type.should be_nil
          @user.pending_cc_last_digits.should be_nil
          @user.pending_cc_expire_on.should be_nil
          @user.cc_type.should == 'visa'
          @user.cc_last_digits.should == '1111'
          @user.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
        end
      end

      context "with a credit card alias" do
        before(:each) do
          @invoice1 = Factory(:invoice, site: Factory(:site, user: @user), state: 'open')
          @invoice2 = Factory(:invoice, site: Factory(:site, user: @user), state: 'failed')
          @invoice3 = Factory(:invoice, site: Factory(:site, user: @user), state: 'paid')
        end

        it "should charge Ogone for the total amount of the open and failed invoices" do
          Ogone.should_receive(:purchase).with(@invoice1.amount + @invoice2.amount, @user.cc_alias, {
            order_id: an_instance_of(String),
            description: an_instance_of(String),
            store: @user.cc_alias,
            email: @user.email,
            billing_address: { zip: @user.postal_code, country: Country[@user.country].name },
            d3d: true,
            paramplus: "PAYMENT=TRUE"
          })
          Transaction.charge_by_invoice_ids([@invoice1.id, @invoice2.id, @invoice3.id])
        end
      end

      context "with a succeeding purchase" do
        before(:each) do
          @invoice1 = Factory(:invoice, site: Factory(:site, user: @user), state: 'open')
        end

        context "credit card" do
          use_vcr_cassette "ogone/visa_payment_2000_credit_card"
          it "should set transaction and invoices to paid state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card }).should be_true
            @invoice1.last_transaction.should be_paid
            @invoice1.reload.should be_paid
          end
        end

        context "alias" do
          use_vcr_cassette "ogone/visa_payment_2000_alias"
          it "should set transaction and invoices to paid state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id]).should be_true
            @invoice1.last_transaction.should be_paid
            @invoice1.reload.should be_paid
          end
        end

        context "with a purchase that need a 3d secure authentication" do
          before(:each) do
            Ogone.stub(:purchase) { mock('response', :params => { "NCSTATUS" => "5", "STATUS" => "46", "HTML_ANSWER" => Base64.encode64("<html>No HTML.</html>") }) }
          end
          
          context "credit card" do
            it "should set transaction and invoices to waiting_d3d state" do
              @invoice1.should be_open
              Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card }).should be_true
              @invoice1.last_transaction.should be_waiting_d3d
              @invoice1.last_transaction.error.should == "<html>No HTML.</html>"
              @invoice1.reload.should be_open
            end
          end

          context "alias" do
            it "should set transaction and invoices to waiting_d3d state" do
              @invoice1.should be_open
              Transaction.charge_by_invoice_ids([@invoice1.id]).should be_true
              @invoice1.last_transaction.should be_waiting_d3d
              @invoice1.last_transaction.error.should == "<html>No HTML.</html>"
              @invoice1.reload.should be_open
            end
          end
        end
      end

      context "with a failing purchase" do
        before(:each) do
          @invoice1 = Factory(:invoice, site: Factory(:site, user: @user), state: 'open')
        end

        context "with a purchase that raise an error" do
          before(:each) { Ogone.stub(:purchase).and_raise("Purchase error!") }
          it "should set transaction and invoices to failed state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card }).should be_false
            @invoice1.last_transaction.should be_failed
            @invoice1.last_transaction.error.should == "Purchase error!"
            @invoice1.reload.should be_failed
          end
        end

        context "with a failing purchase due to an invalid credit card" do
          before(:each) { Ogone.stub(:purchase) { mock('response', :params => { "NCSTATUS" => "5", "STATUS" => "0", "NCERRORPLUS" => "invalid" }) } }
          it "should set transaction and invoices to failed state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card }).should be_false
            @invoice1.last_transaction.should be_failed
            @invoice1.reload.should be_failed
          end
        end

        context "with a failing purchase due to a refused purchase" do
          before(:each) { Ogone.stub(:purchase) { mock('response', :params => { "NCSTATUS" => "3", "STATUS" => "93", "NCERRORPLUS" => "refused" }) } }
          it "should set transaction and invoices to failed state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card }).should be_false
            @invoice1.reload.should be_failed
          end
        end

        context "with a failing purchase due to a waiting authorization" do
          before(:each) { Ogone.stub(:purchase) { mock('response', :params => { "NCSTATUS" => "0", "STATUS" => "51", "NCERRORPLUS" => "waiting" }) } }
          it "should not succeed nor fail transaction nor invoices" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card }).should be_true
            @invoice1.last_transaction.should be_unprocessed
            @invoice1.reload.should be_open
          end
        end

        context "with a failing purchase due to a uncertain result" do
          before(:each) { Ogone.stub(:purchase) { mock('response', :params => { "NCSTATUS" => "2", "STATUS" => "92", "NCERRORPLUS" => "unknown" }) } }
          it "should not succeed nor fail transaction nor invoices, with status 2" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card }).should be_true
            @invoice1.last_transaction.should be_unprocessed
            @invoice1.reload.should be_open
          end
        end

      end

    end # .charge_by_invoice_ids

    describe ".refund_by_site_id" do
      context "for a non-refundable site (the site could have been refunded in the meantime...)" do
        before(:each) do
          @site = Factory(:site, refunded_at: nil)
        end
        
        it "should do nothing!" do
          expect { Transaction.refund_by_site_id(@site.id) }.to_not change(Delayed::Job, :count)
        end
      end

      context "for a non-archived site (the site could have been refunded in the meantime...)" do
        before(:each) do
          @site = Factory(:site, state: 'archived')
        end

        it "should do nothing!" do
          expect { Transaction.refund_by_site_id(@site.id) }.to_not change(Delayed::Job, :count)
        end
      end

      context "for a refundable site with 1 paid transaction" do
        before(:each) do
          @site = Factory(:site_with_invoice, state: 'archived', refunded_at: Time.now.utc)
          transactions = Transaction.paid.joins(:invoices).where(:invoices => { :site_id => @site.id }).order(:id)
          transactions.count.should == 1
          @transaction = transactions.first
        end

        it "should delay one Ogone.credit" do
          expect { Transaction.refund_by_site_id(@site.id) }.to change(Delayed::Job, :count).by(1)

          djs = Delayed::Job.where(:handler.matches => "%credit%")
          djs.count.should == 1
          YAML.load(djs.first.handler)['args'][0].should == @transaction.amount
          YAML.load(djs.first.handler)['args'][1].should == "#{@transaction.pay_id};SAL"
        end
      end

      context "for a refundable site with 1 failed transaction" do
        before(:each) do
          @site = Factory(:site_with_invoice, state: 'archived', refunded_at: Time.now.utc)
          transactions = Transaction.paid.joins(:invoices).where(:invoices => { :site_id => @site.id }).order(:id)
          transactions.count.should == 1
          first_transaction = Transaction.find(transactions.first)
          first_transaction.update_attribute(:state, 'failed')
          first_transaction.should be_failed
        end

        it "should delay one Ogone.credit" do
          expect { Transaction.refund_by_site_id(@site.id) }.to_not change(Delayed::Job, :count)
        end
      end

      context "for a refundable site with multiple transactions all paid" do
        before(:each) do
          @site = Factory(:site_with_invoice, state: 'archived', refunded_at: Time.now.utc)
          @site.plan_id = @custom_plan.token
          VCR.use_cassette("ogone/visa_payment_generic") { @site.save_without_password_validation }
          transactions = Transaction.paid.joins(:invoices).where(:invoices => { :site_id => @site.id }).order(:id)
          transactions.count.should == 2
          @transaction1 = transactions.first
          @transaction2 = transactions.last
        end

        it "should delay one Ogone.credit" do
          expect { Transaction.refund_by_site_id(@site.id) }.to change(Delayed::Job, :count).by(2)

          djs = Delayed::Job.where(:handler.matches => "%credit%")
          djs.count.should == 2
          djs.map { |dj| YAML.load(dj.handler)['args'][0] }.should =~ [@transaction1.amount,  @transaction2.amount]
          djs.map { |dj| YAML.load(dj.handler)['args'][1] }.should =~ ["#{@transaction1.pay_id};SAL", "#{@transaction2.pay_id};SAL"]
        end
      end

      context "for a refundable site with multiple transactions: 1 paid and 1 failed" do
        before(:each) do
          @site = Factory(:site_with_invoice, state: 'archived', refunded_at: Time.now.utc)
          @site.plan_id = @custom_plan.token
          VCR.use_cassette("ogone/visa_payment_generic") { @site.save_without_password_validation }
          transactions = Transaction.paid.joins(:invoices).where(:invoices => { :site_id => @site.id }).order(:id)
          transactions.count.should == 2
          first_transaction = Transaction.find(transactions.first)
          first_transaction.update_attribute(:state, 'failed')
          first_transaction.should be_failed
          @transaction2 = transactions.last
        end

        it "should delay one Ogone.credit" do
          expect { Transaction.refund_by_site_id(@site.id) }.to change(Delayed::Job, :count).by(1)

          djs = Delayed::Job.where(:handler.matches => "%credit%")
          djs.count.should == 1
          YAML.load(djs.last.handler)['args'][0].should == @transaction2.amount
          YAML.load(djs.last.handler)['args'][1].should == "#{@transaction2.pay_id};SAL"
        end
      end
    end

  end # Class Methods

  describe "Instance Methods" do

    describe "#process_payment_response" do
      before(:all) do
        @site1    = Factory(:site, user: @user, plan_id: @dev_plan.id)
        @site2    = Factory(:site, user: @user, plan_id: @paid_plan.id)
        @invoice1 = Factory(:invoice, site: @site1, state: 'open')
        @invoice2 = Factory(:invoice, site: @site2, state: 'failed')
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
      subject { Factory(:transaction, invoices: [@invoice1.reload, @invoice2.reload]) }

      it "should wait_d3d with a STATUS == 46" do
        subject.should be_unprocessed
        subject.error.should be_nil
        subject.process_payment_response(@d3d_params)
        subject.reload.should be_waiting_d3d
        subject.error.should == "<html>No HTML.</html>"
      end

      it "should succeed with a STATUS == 9" do
        subject.should be_unprocessed
        subject.process_payment_response(@success_params)
        subject.reload.should be_paid
      end

      it "should apply pending cc infos to the user" do
        subject.user.update_attributes(pending_cc_type: 'master', pending_cc_last_digits: '9999', pending_cc_expire_on: 2.years.from_now.end_of_month.to_date)
        
        subject.process_payment_response(@success_params)
        
        subject.user.cc_type.should == 'visa'
        subject.user.cc_last_digits.should == '1111'
        subject.user.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
      end

      it "should save with a STATUS == 51" do
        subject.should be_unprocessed
        subject.process_payment_response(@waiting_params)
        subject.reload.should be_unprocessed
        subject.nc_status.should == 0
        subject.status.should == 51
        subject.error.should == "waiting"
        subject.should be_waiting
      end

      it "should fail with a STATUS == 0" do
        subject.should be_unprocessed
        subject.process_payment_response(@invalid_params)
        subject.reload.should be_failed
        subject.nc_status.should == 5
        subject.status.should == 0
        subject.error.should == "invalid"
        subject.should be_invalid
      end

      it "should fail with a STATUS == 93" do
        subject.should be_unprocessed
        subject.process_payment_response(@refused_params)
        subject.reload.should be_failed
        subject.nc_status.should == 3
        subject.status.should == 93
        subject.error.should == "refused"
        subject.should be_refused
      end

      it "should fail with a STATUS == 92" do
        subject.should be_unprocessed
        Notify.should_receive(:send)
        subject.process_payment_response(@unknown_params)
        subject.reload.should be_unprocessed
        subject.nc_status.should == 2
        subject.status.should == 92
        subject.error.should == "unknown"
        subject.should be_unknown
      end

      describe "waiting once, and then succeed" do
        it "should save the transaction and then succeed it" do
          subject.should be_unprocessed
          subject.process_payment_response(@waiting_params)
          subject.reload.should be_unprocessed
          subject.nc_status.should == 0
          subject.status.should == 51
          subject.error.should == "waiting"
          subject.should be_waiting

          subject.process_payment_response(@success_params)
          subject.should be_paid
          subject.nc_status.should == 0
          subject.status.should == 9
          subject.error.should == "!"
        end
      end

      describe "unknown (2) once, and then succeed" do
        it "should save the transaction and then succeed it" do
          subject.should be_unprocessed
          Notify.should_receive(:send)
          subject.process_payment_response(@unknown_params)
          subject.reload.should be_unprocessed
          subject.nc_status.should == 2
          subject.status.should == 92
          subject.error.should == "unknown"
          subject.should be_unknown

          subject.process_payment_response(@success_params)
          subject.should be_paid
          subject.nc_status.should == 0
          subject.status.should == 9
          subject.error.should == "!"
        end
      end

    end

    describe "#description" do
      before(:all) do
        @site1    = Factory(:site, user: @user, plan_id: @dev_plan.id)
        @site2    = Factory(:site, user: @user, plan_id: @paid_plan.id)
        @invoice1 = Factory(:invoice, site: @site1, state: 'open')
        @invoice2 = Factory(:invoice, site: @site2, state: 'failed')
      end
      subject { Factory(:transaction, invoices: [@invoice1.reload, @invoice2.reload]) }

      it "should create a description with invoices references" do
        subject.description.should == "SublimeVideo Invoices: ##{@invoice1.reference}, ##{@invoice2.reference}"
      end
    end

  end

end



# == Schema Information
#
# Table name: transactions
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  order_id   :string(255)
#  state      :string(255)
#  amount     :integer
#  error      :text
#  pay_id     :string(255)
#  nc_status  :integer
#  status     :integer
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_transactions_on_order_id  (order_id) UNIQUE
#

