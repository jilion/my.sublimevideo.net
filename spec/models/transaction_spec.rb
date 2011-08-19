require 'spec_helper'

describe Transaction do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @user_with_no_cc = FactoryGirl.create(:user_no_cc)
  end

  context "Factory" do
    before(:all) { @transaction = FactoryGirl.create(:transaction, invoices: [FactoryGirl.create(:invoice, amount: 1000, state: 'open')]) }
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
      before(:all) { @transaction = FactoryGirl.build(:transaction) }
      subject { @transaction }

      specify { subject.invoices.should be_empty }
      specify { subject.should_not be_valid }
      specify { subject.should have(1).error_on(:base) }
    end

    describe "#all_invoices_belong_to_same_user" do
      before(:all) do
        site1 = FactoryGirl.create(:site)
        site2 = FactoryGirl.create(:site)
        @transaction = FactoryGirl.build(:transaction, invoices: [FactoryGirl.create(:invoice, site: site1), FactoryGirl.create(:invoice, site: site2)])
      end
      subject { @transaction }

      specify { subject.should_not be_valid }
      specify { subject.should have(1).error_on(:base) }
    end
  end # Validations

  describe "Callbacks" do
    before(:all) do
      @site = FactoryGirl.create(:site)
      @invoice1 = FactoryGirl.create(:invoice, site: @site, amount: 200, state: 'open')
      @invoice2 = FactoryGirl.create(:invoice, site: @site, amount: 300, state: 'paid')
      @invoice3 = FactoryGirl.create(:invoice, site: @site, amount: 400, state: 'failed')
    end
    subject { FactoryGirl.build(:transaction, invoices: [@invoice1, @invoice2, @invoice3]) }

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
      @site        = FactoryGirl.create(:site)
      @invoice1    = FactoryGirl.create(:invoice, site: @site, state: 'open')
      @invoice2    = FactoryGirl.create(:invoice, site: @site, state: 'failed')
      @transaction = FactoryGirl.create(:transaction, invoices: [@invoice1, @invoice2])
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

      describe "after_transition :on => :succeed, :do => :send_charging_succeeded_email" do
        context "from open" do
          subject { FactoryGirl.create(:transaction, invoices: [FactoryGirl.create(:invoice)]) }

          it "should send an email to invoice.user" do
            subject
            expect { subject.succeed }.to change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.user.email]
          end
        end
      end

      describe "after_transition :on => :fail, :do => :send_charging_failed_email" do
        context "from open" do
          subject { FactoryGirl.create(:transaction, invoices: [FactoryGirl.create(:invoice)]) }

          it "should send an email to invoice.user" do
            subject
            expect { subject.fail }.to change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.user.email]
          end
        end
      end
    end # Transitions

  end # State Machine

  describe "Scopes" do
    before(:all) do
      @site                    = FactoryGirl.create(:site)
      @invoice                 = FactoryGirl.create(:invoice, site: @site, state: 'open')
      @transaction_unprocessed = FactoryGirl.create(:transaction, invoices: [@invoice])
      @transaction_failed      = FactoryGirl.create(:transaction, invoices: [@invoice], state: 'failed')
      @transaction_paid        = FactoryGirl.create(:transaction, invoices: [@invoice], state: 'paid')
    end

    describe "#failed" do
      specify { Transaction.failed.all.should =~ [@transaction_failed] }
    end
  end # Scopes

  describe "Class Methods" do

    describe ".charge_invoices" do
      before(:all) do
        Invoice.delete_all
        @user1    = FactoryGirl.create(:user)
        @user2    = FactoryGirl.create(:user, state: 'suspended')
        @site1    = FactoryGirl.create(:site, user: @user1)
        @site2    = FactoryGirl.create(:site, user: @user2)
        @invoice1 = FactoryGirl.create(:invoice, state: 'open', site: @site1, renew: true)
        @invoice2 = FactoryGirl.create(:invoice, state: 'open', site: @site1, renew: false)
        @invoice3 = FactoryGirl.create(:invoice, state: 'failed', site: @site1)
        @invoice4 = FactoryGirl.create(:invoice, state: 'failed', site: @site2)
        @invoice5 = FactoryGirl.create(:invoice, state: 'paid', site: @site1)
      end
      before(:each) { Delayed::Job.delete_all }

      it "should delay invoice charging for open invoices which have the renew flag == true by user" do
        Delayed::Job.where(:handler.matches => "%charge_invoices_by_user_id%").count.should == 0
        expect { Transaction.charge_invoices }.to change(Delayed::Job.where(:handler.matches => "%charge_invoices_by_user_id%"), :count).by(1)
        djs = Delayed::Job.where(:handler.matches => "%charge_invoices_by_user_id%")
        djs.count.should == 1
        djs.map { |dj| YAML.load(dj.handler)['args'][0] }.should =~ [@invoice1.reload.site.user.id]
      end
    end # .charge_invoices

    describe ".charge_invoices_by_user_id" do
      use_vcr_cassette "ogone/visa_payment_generic"
      before(:all) do
        Invoice.delete_all
        @user1    = FactoryGirl.create(:user)
        @user2    = FactoryGirl.create(:user)
        @site1    = FactoryGirl.create(:site, user: @user1)
        @site2    = FactoryGirl.create(:new_site, user: @user2)
        @site1.invoices.delete_all
        @site2.invoices.delete_all
        @invoice1 = FactoryGirl.create(:invoice, site: @site1, state: 'paid', renew: false) # first invoice
        @invoice2 = FactoryGirl.create(:invoice, site: @site1, state: 'failed', renew: true)
        @invoice3 = FactoryGirl.create(:invoice, site: @site1, state: 'open', renew: true)
        @invoice4 = FactoryGirl.create(:invoice, site: @site2, state: 'failed', renew: false) # first invoice
      end
      before(:each) do
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
          15.times { FactoryGirl.create(:transaction, invoices: [@invoice2], state: 'failed') }
          Transaction.should_not_receive(:charge_by_invoice_ids)
          Transaction.charge_invoices_by_user_id(@user1.id)
          @invoice2.reload.should be_failed
        end

        it "doesn't try to charge at all if it's the only invoice" do
          @invoice4.reload
          15.times { FactoryGirl.create(:transaction, invoices: [@invoice4], state: 'failed') }
          Transaction.should_not_receive(:charge_by_invoice_ids)
          Transaction.charge_invoices_by_user_id(@user2.id)
        end

        context "invoice is not the first one" do
          it "suspend the user" do
            @invoice2.reload
            15.times { FactoryGirl.create(:transaction, invoices: [@invoice2], state: 'failed') }
            Transaction.should_not_receive(:charge_by_invoice_ids)
            Transaction.charge_invoices_by_user_id(@user1.id)
            @invoice2.reload.should be_failed
            @user1.reload.should be_suspended
          end
        end

        context "invoice is the first one" do
          it "cancels the invoice" do
            @invoice4.reload
            15.times { FactoryGirl.create(:transaction, invoices: [@invoice4], state: 'failed') }
            Transaction.charge_invoices_by_user_id(@user2.id)
            @invoice4.reload.should be_canceled
          end

          it "sends an email to the user" do
            @invoice4.reload
            15.times { FactoryGirl.create(:transaction, invoices: [@invoice4], state: 'failed') }
            expect { Transaction.charge_invoices_by_user_id(@user2.id) }.to change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [@user2.email]
          end
        end
      end
    end # .charge_invoices_by_user_id

    describe ".charge_by_invoice_ids" do
      context "with a new credit card given through options[:credit_card]" do
        before(:each) do
          @user = FactoryGirl.create(:user_no_cc)
          @site1 = FactoryGirl.build(:new_site, user: @user)
          @site1.user.assign_attributes(valid_cc_attributes)
          @credit_card = @site1.user.credit_card
          @site1.charging_options = { credit_card: @credit_card }
          @site1.save_without_password_validation # fake sites_controller

          @user.pending_cc_type.should eql 'visa'
          @user.pending_cc_last_digits.should eql '1111'
          @user.pending_cc_expire_on.should eql 1.year.from_now.end_of_month.to_date
          @user.cc_type.should be_nil
          @user.cc_last_digits.should be_nil
          @user.cc_expire_on.should be_nil

          @invoice1 = FactoryGirl.create(:invoice, site: @site1, state: 'open')
        end

        it "should charge Ogone for the total amount of the open and failed invoices" do
          Ogone.should_receive(:purchase).with(@invoice1.amount, @site1.charging_options[:credit_card], {
            order_id: an_instance_of(String),
            description: an_instance_of(String),
            store: @user.cc_alias,
            email: @user.email,
            billing_address: { zip: @user.postal_code, country: @user.country },
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

        it "should store cc infos from the credit card" do
          VCR.use_cassette("ogone/visa_payment_2000_credit_card") do
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @credit_card }).should be_true
          end

          @invoice1.last_transaction.cc_type.should == @credit_card.type
          @invoice1.last_transaction.cc_last_digits.should == @credit_card.last_digits
          @invoice1.last_transaction.cc_expire_on.should == Time.utc(@credit_card.year, @credit_card.month).end_of_month.to_date
        end
      end

      context "with a credit card alias" do
        before(:each) do
          @invoice1 = FactoryGirl.create(:invoice, site: FactoryGirl.create(:site, user: @user), state: 'open')
          @invoice2 = FactoryGirl.create(:invoice, site: FactoryGirl.create(:site, user: @user), state: 'failed')
          @invoice3 = FactoryGirl.create(:invoice, site: FactoryGirl.create(:site, user: @user), state: 'paid')
        end

        it "should charge Ogone for the total amount of the open and failed invoices" do
          Ogone.should_receive(:purchase).with(@invoice1.amount + @invoice2.amount, @user.cc_alias, {
            order_id: an_instance_of(String),
            description: an_instance_of(String),
            store: @user.cc_alias,
            email: @user.email,
            billing_address: { zip: @user.postal_code, country: @user.country },
            d3d: true,
            paramplus: "PAYMENT=TRUE"
          })
          Transaction.charge_by_invoice_ids([@invoice1.id, @invoice2.id, @invoice3.id])
        end

        it "should store cc infos from the user" do
          VCR.use_cassette("ogone/visa_payment_2000_credit_card") do
            Transaction.charge_by_invoice_ids([@invoice1.id, @invoice2.id, @invoice3.id])
          end

          @invoice1.last_transaction.cc_type.should == @user.cc_type
          @invoice1.last_transaction.cc_last_digits.should == @user.cc_last_digits
          @invoice1.last_transaction.cc_expire_on.should == @user.cc_expire_on
        end
      end

      context "with a succeeding purchase" do
        before(:each) do
          @invoice1 = FactoryGirl.create(:invoice, site: FactoryGirl.create(:site, user: @user), state: 'open')
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
          @invoice1 = FactoryGirl.create(:invoice, site: FactoryGirl.create(:site, user: @user), state: 'open')
        end

        context "with a purchase that raise an error" do
          before(:each) { Ogone.stub(:purchase).and_raise("Purchase error!") }
          it "should set transaction and invoices to failed state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.last_transaction.should be_failed
            @invoice1.last_transaction.error.should == "Purchase error!"
            @invoice1.reload.should be_failed
          end
        end

        context "with a failing purchase due to an invalid credit card" do
          before(:each) { Ogone.stub(:purchase) { mock('response', :params => { "NCSTATUS" => "5", "STATUS" => "0", "NCERRORPLUS" => "invalid" }) } }
          it "should set transaction and invoices to failed state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.last_transaction.should be_failed
            @invoice1.reload.should be_failed
          end
        end

        context "with a failing purchase due to a refused purchase" do
          before(:each) { Ogone.stub(:purchase) { mock('response', :params => { "NCSTATUS" => "3", "STATUS" => "93", "NCERRORPLUS" => "refused" }) } }
          it "should set transaction and invoices to failed state" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.reload.should be_failed
          end
        end

        context "with a failing purchase due to a waiting authorization" do
          before(:each) { Ogone.stub(:purchase) { mock('response', :params => { "NCSTATUS" => "0", "STATUS" => "51", "NCERRORPLUS" => "waiting" }) } }
          it "should not succeed nor fail transaction nor invoices" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.last_transaction.should be_waiting
            @invoice1.reload.should be_waiting
          end
        end

        context "with a failing purchase due to a uncertain result" do
          before(:each) { Ogone.stub(:purchase) { mock('response', :params => { "NCSTATUS" => "2", "STATUS" => "92", "NCERRORPLUS" => "unknown" }) } }
          it "should not succeed nor fail transaction nor invoices, with status 2" do
            @invoice1.should be_open
            Transaction.charge_by_invoice_ids([@invoice1.id], { credit_card: @user.credit_card })
            @invoice1.last_transaction.should be_waiting
            @invoice1.reload.should be_waiting
          end
        end

      end

    end # .charge_by_invoice_ids

    describe ".refund_by_site_id" do
      context "for a non-refundable site" do
        describe "because of a not present refunded_at" do
          it "does nothing!" do
            site = FactoryGirl.create(:site, refunded_at: nil)
            expect { Transaction.refund_by_site_id(site.id) }.to_not change(Delayed::Job, :count)
          end
        end
        describe "because of a too old first_paid_plan_started_at" do
          it "does nothing!" do
            site = FactoryGirl.create(:site, first_paid_plan_started_at: 31.days.ago, refunded_at: Time.now.utc)
            expect { Transaction.refund_by_site_id(site.id) }.to_not change(Delayed::Job, :count)
          end
        end
        describe "because of a non-archived site" do
          it "does nothing!" do
            site = FactoryGirl.create(:site, first_paid_plan_started_at: 29.days.ago, refunded_at: Time.now.utc)
            expect { Transaction.refund_by_site_id(site.id) }.to_not change(Delayed::Job, :count)
          end
        end
      end

      context "for a refundable site with 1 paid transaction containing 2 invoices with 2 different sites" do
        before(:each) do
          @site = FactoryGirl.create(:site_with_invoice, state: 'archived', refunded_at: Time.now.utc)
          Site.refunded.should include(@site)
          @site.invoices.where(state: 'paid').count.should eql 1
          transactions = Transaction.paid.joins(:invoices).where { invoices.site_id == my{@site.id} }.order(:id)
          transactions.count.should eql 1

          @transaction = transactions.first
          @transaction.invoices.where(state: 'paid').count.should eql 1
          @transaction.invoices << FactoryGirl.create(:invoice, site: FactoryGirl.create(:site), state: 'paid') # the transaction is with 2 invoices for 2 different sites
          @transaction.save
          @transaction.reload.invoices.where(state: 'paid').count.should eql 2
          @transaction.should be_paid
        end

        it "delays one Ogone.credit" do
          Ogone.should_receive(:credit).with(@site.invoices.first.amount, "#{@transaction.pay_id};SAL")
          Transaction.refund_by_site_id(@site.id)
        end

        it "deducts refunded invoices from the user's total_invoiced_amount and update the last_invoiced_amount" do
          @site.user.last_invoiced_amount.should eql @site.invoices.where(state: 'paid').order(:paid_at.desc).first.amount
          @site.user.total_invoiced_amount.should eql @site.invoices.where(state: 'paid').order(:paid_at.desc).first.amount
          Ogone.should_receive(:credit).with(@site.invoices.first.amount, "#{@transaction.pay_id};SAL")
          Transaction.refund_by_site_id(@site.id)
          @site.user.reload.last_invoiced_amount.should eql 0
          @site.user.total_invoiced_amount.should eql 0
        end
      end

      context "for a refundable site with 1 failed transaction" do
        before(:each) do
          @site = FactoryGirl.create(:site_with_invoice, state: 'archived', refunded_at: Time.now.utc)
          transactions = Transaction.paid.joins(:invoices).where(:invoices => { :site_id => @site.id }).order(:id)
          transactions.count.should == 1

          @transaction = Transaction.find(transactions.first.id)
          @transaction.invoices.where(state: 'paid').count.should == 1
          @transaction.reload.update_attribute(:state, 'failed')
          @transaction.reload.should be_failed
          @transaction.invoices.first.update_attribute(:state, 'failed')
          @transaction.reload.invoices.where(state: 'paid').count.should == 0
          @transaction.invoices.first.should be_failed
        end

        it "should delay one Ogone.credit" do
          Ogone.should_not_receive(:credit)
          Transaction.refund_by_site_id(@site.id)
        end
      end

      context "for a refundable site with multiple transactions all paid" do
        before(:each) do
          @site = FactoryGirl.create(:site_with_invoice)
          @site2 = FactoryGirl.create(:site_with_invoice, user: @site.user)
          @site.plan_id = @custom_plan.token
          VCR.use_cassette("ogone/visa_payment_generic") { @site.save_without_password_validation }
          @site.without_password_validation { @site.archive }
          @site.refund
          transactions = Transaction.paid.joins(:invoices).where { invoices.site_id == my{@site.id} }.order(:id.asc)
          transactions.count.should eql 2
          @transaction1 = Transaction.find(transactions.first.id)
          @transaction1.reload.update_attribute(:amount, 3209999)
          @transaction2 = Transaction.find(transactions.last.id)
          @transaction2.reload.update_attribute(:amount, 23213)

          @transaction1.invoices.where(state: 'paid').count.should eql 1
          @transaction2.invoices.where(state: 'paid').count.should eql 1
          @transaction2.invoices << FactoryGirl.create(:invoice, site: FactoryGirl.create(:site), state: 'failed') # the transaction is with 2 invoices for 2 different sites
          @transaction2.save
          @transaction2.reload.invoices.where(state: 'paid').count.should eql 1
          @transaction1.should be_paid
          @transaction2.should be_paid

          @site.invoices.first.amount.should_not eql @transaction1.amount
          @site.invoices.last.amount.should_not eql @transaction2.amount
        end

        it "calls one Ogone.credit" do
          Ogone.should_receive(:credit).ordered.with(@transaction1.invoices.order(:id.asc).first.amount, "#{@transaction1.pay_id};SAL")
          Ogone.should_receive(:credit).ordered.with(@transaction2.invoices.order(:id.asc).first.amount, "#{@transaction2.pay_id};SAL")

          Transaction.refund_by_site_id(@site.id)
        end

        it "deducts refunded invoices from the user's total_invoiced_amount and update the last_invoiced_amount" do
          @site.user.update_attribute(:last_invoiced_amount, 20000)
          @site.user.update_attribute(:total_invoiced_amount, 100000)
          @site.reload.user.last_invoiced_amount.should eql 20000
          @site.user.total_invoiced_amount.should eql 100000
          Ogone.should_receive(:credit).ordered.with(@transaction1.invoices.order(:id.asc).first.amount, "#{@transaction1.pay_id};SAL")
          Ogone.should_receive(:credit).ordered.with(@transaction2.invoices.order(:id.asc).first.amount, "#{@transaction2.pay_id};SAL")

          Transaction.refund_by_site_id(@site.id)
          @site.user.reload.last_invoiced_amount.should eql @site2.last_paid_invoice.amount
          @site.user.total_invoiced_amount.should eql @site2.last_paid_invoice.amount
        end
      end

      context "for a refundable site with multiple transactions: 1 paid and 1 failed" do
        before(:each) do
          @site = FactoryGirl.create(:site_with_invoice)
          @site2 = FactoryGirl.create(:site_with_invoice, user: @site.user)
          @site.plan_id = @custom_plan.token
          VCR.use_cassette("ogone/visa_payment_generic") { @site.save_without_password_validation }
          @site.without_password_validation { @site.archive }
          @site.refund
          transactions = Transaction.paid.joins(:invoices).where{ invoices.site_id == my{@site.id} }.order(:id.asc)
          transactions.count.should eql 2
          @transaction1 = Transaction.find(transactions.first.id)
          @transaction1.reload.update_attribute(:amount, 3209999)
          @transaction1.invoices.first.update_attribute(:state, 'failed')
          @transaction2 = Transaction.find(transactions.last.id)
          @transaction2.reload.update_attribute(:amount, 23213)

          @transaction1.invoices << FactoryGirl.create(:invoice, site: FactoryGirl.create(:site), state: 'paid') # the transaction is with 2 invoices for 2 different sites
          @transaction2.invoices << FactoryGirl.create(:invoice, site: FactoryGirl.create(:site), state: 'failed') # the transaction is with 2 invoices for 2 different sites
          @transaction1.save
          @transaction2.save

          @transaction1.invoices.first.amount.should_not eql @transaction1.amount
          @transaction2.invoices.first.amount.should_not eql @transaction2.amount
        end

        it "should delay one Ogone.credit" do
          Ogone.should_receive(:credit).with(@transaction2.invoices.order(:id.asc).first.amount, "#{@transaction2.pay_id};SAL")

          Transaction.refund_by_site_id(@site.id)
        end

        it "deducts refunded invoices from the user's total_invoiced_amount and update the last_invoiced_amount" do
          @site.user.update_attribute(:last_invoiced_amount, 20000)
          @site.user.update_attribute(:total_invoiced_amount, 100000)
          @site.reload.user.last_invoiced_amount.should eql 20000
          @site.user.total_invoiced_amount.should eql 100000
          Ogone.should_receive(:credit).with(@transaction2.invoices.order(:id.asc).first.amount, "#{@transaction2.pay_id};SAL")

          Transaction.refund_by_site_id(@site.id)
          @site.user.reload.last_invoiced_amount.should eql @site2.last_paid_invoice.amount
          @site.user.total_invoiced_amount.should eql @site2.last_paid_invoice.amount
        end
      end
    end

  end # Class Methods

  describe "Instance Methods" do

    describe "#process_payment_response" do
      before(:all) do
        @site1    = FactoryGirl.create(:site, user: @user, plan_id: @free_plan.id)
        @site2    = FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
        @invoice1 = FactoryGirl.create(:invoice, site: @site1, state: 'open')
        @invoice2 = FactoryGirl.create(:invoice, site: @site2, state: 'failed')
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
      subject { FactoryGirl.create(:transaction, invoices: [@invoice1.reload, @invoice2.reload]) }

      it "should wait_d3d with a STATUS == 46" do
        subject.should be_unprocessed
        subject.error.should be_nil

        subject.process_payment_response(@d3d_params)
        subject.reload.should be_waiting_d3d
        subject.error.should == "<html>No HTML.</html>"
        @invoice1.reload.should be_open
        @invoice2.reload.should be_failed
      end

      it "should succeed with a STATUS == 9" do
        subject.should be_unprocessed

        subject.process_payment_response(@success_params)
        subject.reload.should be_paid
        @invoice1.reload.should be_paid
        @invoice2.reload.should be_paid
      end

      it "should apply pending cc infos to the user" do
        subject.user.cc_brand = 'master'
        subject.user.cc_full_name = 'Remy Coutable'
        subject.user.cc_number = '5399999999999999'
        subject.user.cc_expiration_month = 2.years.from_now.month
        subject.user.cc_expiration_year = 2.years.from_now.year
        subject.user.cc_verification_value = 999
        subject.user.save!
        subject.user.reload.pending_cc_type.should == 'master'
        subject.user.pending_cc_last_digits.should == '9999'
        subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date

        subject.process_payment_response(@success_params)
        subject.user.reload.cc_type.should == 'master'
        subject.user.cc_last_digits.should == '9999'
        subject.user.cc_expire_on.should == 2.years.from_now.end_of_month.to_date
      end

      it "should save with a STATUS == 51" do
        subject.should be_unprocessed

        subject.process_payment_response(@waiting_params)
        subject.reload.should be_waiting
        subject.nc_status.should == 0
        subject.status.should == 51
        subject.error.should == "waiting"
        @invoice1.reload.should be_waiting
        @invoice2.reload.should be_waiting
      end

      it "should fail with a STATUS == 0" do
        subject.should be_unprocessed

        subject.process_payment_response(@invalid_params)
        subject.reload.should be_failed
        subject.nc_status.should == 5
        subject.status.should == 0
        subject.error.should == "invalid"
        @invoice1.reload.should be_failed
        @invoice2.reload.should be_failed
      end

      it "should clear pending cc infos of the user" do
        subject.user.cc_brand = 'master'
        subject.user.cc_full_name = 'Remy Coutable'
        subject.user.cc_number = '5399999999999999'
        subject.user.cc_expiration_month = 2.years.from_now.month
        subject.user.cc_expiration_year = 2.years.from_now.year
        subject.user.cc_verification_value = 999
        subject.user.save!
        subject.user.reload.pending_cc_type.should == 'master'
        subject.user.pending_cc_last_digits.should == '9999'
        subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date

        subject.process_payment_response(@invalid_params)
        subject.user.reload.cc_type.should == 'visa'
        subject.user.cc_last_digits.should == '1111'
        subject.user.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
        subject.user.pending_cc_last_digits.should == '9999'
        subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
        subject.user.pending_cc_updated_at.should be_present
      end

      it "should fail with a STATUS == 93" do
        subject.should be_unprocessed

        subject.process_payment_response(@refused_params)
        subject.reload.should be_failed
        subject.nc_status.should == 3
        subject.status.should == 93
        subject.error.should == "refused"
        @invoice1.reload.should be_failed
        @invoice2.reload.should be_failed
      end

      it "should clear pending cc infos of the user" do
        subject.user.cc_brand = 'master'
        subject.user.cc_full_name = 'Remy Coutable'
        subject.user.cc_number = '5399999999999999'
        subject.user.cc_expiration_month = 2.years.from_now.month
        subject.user.cc_expiration_year = 2.years.from_now.year
        subject.user.cc_verification_value = 999
        subject.user.save!
        subject.user.reload.pending_cc_type.should == 'master'
        subject.user.pending_cc_last_digits.should == '9999'
        subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date

        subject.process_payment_response(@refused_params)
        subject.user.reload.cc_type.should == 'visa'
        subject.user.cc_last_digits.should == '1111'
        subject.user.cc_expire_on.should == 1.year.from_now.end_of_month.to_date
        subject.user.pending_cc_last_digits.should == '9999'
        subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
        subject.user.pending_cc_updated_at.should be_present
      end

      it "should fail with a STATUS == 92" do
        subject.should be_unprocessed
        Notify.should_receive(:send)

        subject.process_payment_response(@unknown_params)
        subject.reload.should be_waiting
        subject.nc_status.should == 2
        subject.status.should == 92
        subject.error.should == "unknown"
        @invoice1.reload.should be_waiting
        @invoice2.reload.should be_waiting
      end

      it "should not clear pending cc infos of the user" do
        subject.user.cc_brand = 'master'
        subject.user.cc_full_name = 'Remy Coutable'
        subject.user.cc_number = '5399999999999999'
        subject.user.cc_expiration_month = 2.years.from_now.month
        subject.user.cc_expiration_year = 2.years.from_now.year
        subject.user.cc_verification_value = 999
        subject.user.save!
        subject.user.reload.pending_cc_type.should == 'master'
        subject.user.pending_cc_last_digits.should == '9999'
        subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date

        subject.process_payment_response(@unknown_params)
        subject.user.reload.pending_cc_type.should == 'master'
        subject.user.pending_cc_last_digits.should == '9999'
        subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
      end

      describe "waiting d3d once, and then succeed" do
        it "should save the transaction and then succeed it" do
          subject.user.cc_brand = 'master'
          subject.user.cc_full_name = 'Remy Coutable'
          subject.user.cc_number = '5399999999999999'
          subject.user.cc_expiration_month = 2.years.from_now.month
          subject.user.cc_expiration_year = 2.years.from_now.year
          subject.user.cc_verification_value = 999
          subject.user.save!
          subject.user.reload.pending_cc_type.should == 'master'
          subject.user.pending_cc_last_digits.should == '9999'
          subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
          subject.should be_unprocessed

          subject.process_payment_response(@d3d_params)
          subject.reload.should be_waiting_d3d
          subject.nc_status.should == 0
          subject.status.should == 46
          subject.error.should == "<html>No HTML.</html>"
          subject.should be_waiting_d3d
          subject.user.reload.pending_cc_type.should == 'master'
          subject.user.pending_cc_last_digits.should == '9999'
          subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
          @invoice1.reload.should be_open
          @invoice2.reload.should be_failed

          subject.process_payment_response(@success_params)
          subject.reload.should be_paid
          subject.nc_status.should == 0
          subject.status.should == 9
          subject.error.should == "!"

          subject.user.reload.pending_cc_type.should be_nil
          subject.user.pending_cc_last_digits.should be_nil
          subject.user.pending_cc_expire_on.should be_nil
          subject.user.reload.cc_type.should == 'master'
          subject.user.cc_last_digits.should == '9999'
          subject.user.cc_expire_on.should == 2.years.from_now.end_of_month.to_date
          @invoice1.reload.should be_paid
          @invoice2.reload.should be_paid
        end
      end

      describe "waiting once, and then succeed" do
        it "should save the transaction and then succeed it" do
          subject.user.cc_brand = 'master'
          subject.user.cc_full_name = 'Remy Coutable'
          subject.user.cc_number = '5399999999999999'
          subject.user.cc_expiration_month = 2.years.from_now.month
          subject.user.cc_expiration_year = 2.years.from_now.year
          subject.user.cc_verification_value = 999
          subject.user.save!
          subject.user.reload.pending_cc_type.should == 'master'
          subject.user.pending_cc_last_digits.should == '9999'
          subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
          subject.should be_unprocessed

          subject.process_payment_response(@waiting_params)
          subject.reload.should be_waiting
          subject.nc_status.should == 0
          subject.status.should == 51
          subject.error.should == "waiting"
          subject.should be_waiting
          subject.user.reload.pending_cc_type.should == 'master'
          subject.user.pending_cc_last_digits.should == '9999'
          subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
          @invoice1.reload.should be_waiting
          @invoice2.reload.should be_waiting

          subject.process_payment_response(@success_params)
          subject.reload.should be_paid
          subject.nc_status.should == 0
          subject.status.should == 9
          subject.error.should == "!"

          subject.user.reload.pending_cc_type.should be_nil
          subject.user.pending_cc_last_digits.should be_nil
          subject.user.pending_cc_expire_on.should be_nil
          subject.user.reload.cc_type.should == 'master'
          subject.user.cc_last_digits.should == '9999'
          subject.user.cc_expire_on.should == 2.years.from_now.end_of_month.to_date
          @invoice1.reload.should be_paid
          @invoice2.reload.should be_paid
        end
      end

      describe "unknown (2) once, and then succeed" do
        it "should save the transaction and then succeed it" do
          subject.user.cc_brand = 'master'
          subject.user.cc_full_name = 'Remy Coutable'
          subject.user.cc_number = '5399999999999999'
          subject.user.cc_expiration_month = 2.years.from_now.month
          subject.user.cc_expiration_year = 2.years.from_now.year
          subject.user.cc_verification_value = 999
          subject.user.save!
          subject.user.reload.pending_cc_type.should == 'master'
          subject.user.pending_cc_last_digits.should == '9999'
          subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
          subject.should be_unprocessed
          Notify.should_receive(:send)

          subject.process_payment_response(@unknown_params)
          subject.reload.should be_waiting
          subject.nc_status.should == 2
          subject.status.should == 92
          subject.error.should == "unknown"
          subject.user.reload.pending_cc_type.should == 'master'
          subject.user.pending_cc_last_digits.should == '9999'
          subject.user.pending_cc_expire_on.should == 2.years.from_now.end_of_month.to_date
          @invoice1.reload.should be_waiting
          @invoice2.reload.should be_waiting

          subject.process_payment_response(@success_params)
          subject.reload.should be_paid
          subject.nc_status.should == 0
          subject.status.should == 9
          subject.error.should == "!"
          subject.user.reload.pending_cc_type.should be_nil
          subject.user.pending_cc_last_digits.should be_nil
          subject.user.pending_cc_expire_on.should be_nil
          subject.user.reload.cc_type.should == 'master'
          subject.user.cc_last_digits.should == '9999'
          subject.user.cc_expire_on.should == 2.years.from_now.end_of_month.to_date
          @invoice1.reload.should be_paid
          @invoice2.reload.should be_paid
        end
      end
    end

    describe "#description" do
      before(:all) do
        @site1    = FactoryGirl.create(:site, user: @user, plan_id: @free_plan.id)
        @site2    = FactoryGirl.create(:site, user: @user, plan_id: @paid_plan.id)
        @invoice1 = FactoryGirl.create(:invoice, site: @site1, state: 'open')
        @invoice2 = FactoryGirl.create(:invoice, site: @site2, state: 'failed')
      end
      subject { FactoryGirl.create(:transaction, invoices: [@invoice1.reload, @invoice2.reload]) }

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
#  id             :integer         not null, primary key
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
#  created_at     :datetime
#  updated_at     :datetime
#
# Indexes
#
#  index_transactions_on_order_id  (order_id) UNIQUE
#

