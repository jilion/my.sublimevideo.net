require 'spec_helper'

describe Invoice do

  describe "Factory" do
    subject { Factory.create(:invoice) }

    its(:site)                     { should be_present }
    its(:reference)                { should =~ /^[a-z1-9]{8}$/ }
    its(:invoice_items_amount)     { should eql 10000 }
    its(:balance_deduction_amount) { should eql 0 }
    its(:amount)                   { should eql 10000 }
    its(:paid_at)                  { should be_nil }
    its(:last_failed_at)           { should be_nil }

    it { should be_open } # initial state
    it { should be_valid }
  end # Factory

  describe "Associations" do
    subject { Factory.create(:invoice) }

    it { should belong_to :site }
    it { should have_one :user }
    it { should have_many :invoice_items }
    it { should have_and_belong_to_many :transactions }
  end # Associations

  describe "Validations" do
    subject { Factory.create(:invoice) }

    [:site, :renew].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end

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

    describe "ensure_first_invoice_of_site" do

      context "first invoice" do
        before(:each) do
          Invoice.delete_all
          @site = Factory.create(:new_site, first_paid_plan_started_at: nil)
          @site.first_paid_plan_started_at.should be_nil
        end

        context "with an open invoice" do
          subject { Factory.create(:invoice, site: @site, state: 'open') }

          it "cancels the invoice" do
            subject.cancel!.should be_true
            subject.should be_canceled
          end
        end

        context "with a failed invoice" do
          subject { Factory.create(:invoice, site: @site, state: 'failed') }

          it "cancels the invoice" do
            subject.cancel!.should be_true
            subject.should be_canceled
          end
        end

        context "with a waiting invoice" do
          subject { Factory.create(:invoice, site: @site, state: 'waiting') }

          it "cancels the invoice" do
            subject.cancel.should be_false
            subject.should be_waiting
          end
        end
      end

      context "not first invoice" do
        before(:each) do
          Invoice.delete_all
          @site = Factory.create(:new_site, first_paid_plan_started_at: Time.now.utc)
          @site.first_paid_plan_started_at.should be_present
        end

        context "with an open invoice" do
           subject { Factory.create(:invoice, site: @site, state: 'open') }

          it "doesn't cancel the invoice" do
            subject.cancel.should be_false
            subject.should be_open
          end
        end

        context "with a failed invoice" do
          subject { Factory.create(:invoice, site: @site, state: 'failed') }

          it "doesn't cancel the invoice" do
            subject.cancel.should be_false
            subject.should be_failed
          end
        end

        context "with a waiting invoice" do
          subject { Factory.create(:invoice, site: @site, state: 'waiting') }

          it "doesn't cancel the invoice" do
            subject.cancel.should be_false
            subject.should be_waiting
          end
        end
      end
    end

  end # Validations

  describe "State Machine" do
    subject { Factory.create(:invoice) }

    describe "Initial state" do
      it { should be_open }
    end

    describe "Transitions" do
      describe "before_transition :on => :succeed, :do => :set_paid_at" do
        before { subject.reload }

        it "should set paid_at" do
          subject.paid_at.should be_nil
          subject.succeed!
          subject.paid_at.should be_present
        end
      end

      describe "before_transition :on => :fail, :do => :set_last_failed_at" do
        before { subject.reload }

        it "should set last_failed_at" do
          subject.last_failed_at.should be_nil
          subject.fail!
          subject.last_failed_at.should be_present
        end
      end

      describe "after_transition :on => :succeed, :do => :apply_site_pending_attributes" do
        context "with a site with no more non-paid invoices" do
          it "should call #apply_pending_attributes on the site" do
            site = Factory.create(:site)

            invoice = Factory.create(:invoice, site: site)
            invoice.site.should_receive(:apply_pending_attributes)
            invoice.succeed!
            invoice.reload.should be_paid
          end
        end

        %w[open waiting failed].each do |state|
          context "with a site with an #{state} invoice present" do
            let(:site) { Factory.create(:site) }
            let(:non_paid_invoice) { Factory.create(:invoice, state: state, site: site) }

            it "should not call #apply_pending_attributes on the site only if there are still non-paid invoices" do
              non_paid_invoice.state.should eq state

              non_paid_invoice.site.should_not_receive(:apply_pending_attributes)
              Factory.create(:invoice, site: site).succeed!
            end

            it "should call #apply_pending_attributes on the site if there are no more non-paid invoices" do
              non_paid_invoice.state.should eq state

              non_paid_invoice.site.should_receive(:apply_pending_attributes).once
              Factory.create(:invoice, site: site).succeed!
              non_paid_invoice.succeed!
            end
          end
        end
      end

      describe "after_transition :on => :succeed, :do => :update_user_invoiced_amount" do
        before  { subject.reload }

        it "should update user.last_invoiced_amount" do
          subject.user.update_attribute(:last_invoiced_amount, 500)
          expect { subject.succeed! }.should change(subject.user.reload, :last_invoiced_amount).from(500).to(10000)
        end

        it "should increment user.total_invoiced_amount" do
          subject.user.update_attribute(:total_invoiced_amount, 500)
          expect { subject.succeed! }.should change(subject.user.reload, :total_invoiced_amount).from(500).to(10500)
        end

        it "should save user" do
          old_user_last_invoiced_amount = subject.user.last_invoiced_amount
          old_user_total_invoiced_amount = subject.user.total_invoiced_amount
          subject.succeed!
          subject.user.reload
          subject.user.last_invoiced_amount.should_not eq old_user_last_invoiced_amount
          subject.user.total_invoiced_amount.should_not eq old_user_total_invoiced_amount
        end
      end

      describe "after_transition :on => :succeed, :do => :unsuspend_user" do
        before  { subject.reload }

        context "with a non-suspended user" do
          %w[open failed].each do |state|
            context "from #{state}" do
              before(:each) do
                subject.reload.update_attributes(state: state, amount: 0)
                subject.user.should be_active
              end

              it "should not un-suspend_user" do
                subject.succeed!
                subject.should be_paid
                subject.user.should be_active
              end
            end
          end
        end

        context "with a suspended user" do
          %w[open failed].each do |state|
            context "from #{state}" do
              before(:each) do
                subject.reload.update_attributes(state: state, amount: 0)
                subject.user.update_attribute(:state, 'suspended')
                subject.user.should be_suspended
              end

              context "with no more open invoice" do
                it "should un-suspend_user" do
                  subject.succeed!
                  subject.should be_paid
                  subject.user.should be_active
                end
              end

              context "with more failed invoice" do
                before(:each) do
                  Factory.create(:invoice, site: Factory.create(:site, user: subject.user), state: 'failed')
                end

                it "should not delay un-suspend_user" do
                  subject.succeed!
                  subject.should be_paid
                  subject.user.should be_suspended
                end
              end
            end
          end
        end
      end

      describe "after_transition :on => :cancel, :do => :increment_user_balance" do
        before  { subject.reload }

        it "increments user balance" do
          subject.update_attribute(:balance_deduction_amount, 2000)
          subject.user.update_attribute(:balance, 1000)

          subject.should be_open
          expect { subject.cancel! }.should change(subject.user.reload, :balance).from(1000).to(3000)
          subject.should be_canceled
        end
      end

    end # Transitions

  end # State Machine

  describe "Callbacks" do
    describe "#before_validation, on: create" do
      before  { @invoice = Factory.create(:invoice) } # need to have access to invoice inside its block
      subject { @invoice }

      describe "#set_customer_info" do
        its(:customer_full_name)       { should eql @invoice.user.billing_name }
        its(:customer_email)           { should eql @invoice.user.email }
        its(:customer_country)         { should eql @invoice.user.billing_country }
        its(:customer_company_name)    { should eql @invoice.user.company_name }
        its(:customer_billing_address) { should eql @invoice.user.billing_address }
      end

      describe "#set_site_info" do
        its(:site_hostname) { should eql @invoice.site.hostname }
      end
    end

    describe "#after_create" do
      context "balance > invoice amount" do

        describe "succeed invoice with amount == 0" do
          before(:each) do
            @user = Factory.create(:user, billing_country: 'FR', balance: 2000)
            @site = Factory.build(:site_not_in_trial, user: @user, plan_id: @paid_plan.id)
            @invoice = Invoice.construct(site: @site)
            @invoice.save!
          end
          subject { @invoice }

          its(:invoice_items_amount)     { should eql 1000 }
          its(:balance_deduction_amount) { should eql 1000 }
          its(:amount)                   { should eql 0 }
          it { should be_paid }
        end

        describe "#decrement_user_balance" do
          before(:each) do
            @user = Factory.create(:user, billing_country: 'FR', balance: 2000)
            @site = Factory.build(:site_not_in_trial, user: @user, plan_id: @paid_plan.id)
            @invoice = Invoice.construct(site: @site)
            @invoice.save!
          end
          subject { @invoice }

          its(:balance_deduction_amount) { should eql 1000 }
          its(:amount)                   { should eql 0 }
          its("user.balance")            { should eql 1000 }
        end

      end
    end
  end

  describe "Scopes" do
    before(:each) do
      @site             = Factory.create(:new_site, plan_id: @paid_plan.id, refunded_at: nil)
      @site2            = Factory.create(:new_site)

      Invoice.delete_all
      @refunded_site    = Factory.create(:site, plan_id: @paid_plan.id, refunded_at: Time.now.utc)
      @open_invoice     = Factory.create(:invoice, site: @site, state: 'open', created_at: 48.hours.ago)
      @failed_invoice   = Factory.create(:invoice, site: @site, state: 'failed', created_at: 25.hours.ago)
      @waiting_invoice  = Factory.create(:invoice, site: @site, state: 'waiting', created_at: 18.hours.ago)
      @paid_invoice     = Factory.create(:invoice, site: @site, state: 'paid', created_at: 16.hours.ago)
      @canceled_invoice = Factory.create(:invoice, site: @site2, state: 'canceled', created_at: 14.hours.ago)
      @refunded_invoice = Factory.create(:invoice, site: @refunded_site, state: 'paid', created_at: 14.hours.ago)

      @open_invoice.should be_open
      @failed_invoice.should be_failed
      @waiting_invoice.should be_waiting
      @paid_invoice.should be_paid
      @canceled_invoice.should be_canceled
      @refunded_invoice.should be_refunded
    end

    describe "#between" do
      specify { Invoice.between(24.hours.ago, 15.hours.ago).order(:id).should eq [@waiting_invoice, @paid_invoice] }
    end

    describe "#open" do
      specify { Invoice.open.order(:id).should eq [@open_invoice] }
    end

    describe "#paid" do
      specify { Invoice.paid.order(:id).should eq [@paid_invoice] }
    end

    describe "#refunded" do
      specify { Invoice.refunded.order(:id).should eq [@refunded_invoice] }
    end

    describe "#failed" do
      specify { Invoice.failed.order(:id).should eq [@failed_invoice] }
    end

    describe "#waiting" do
      specify { Invoice.waiting.order(:id).should eq [@waiting_invoice] }
    end

    describe "#open_or_failed" do
      specify { Invoice.open_or_failed.order(:id).should eq [@open_invoice, @failed_invoice] }
    end

    describe "#not_canceled" do
      specify { Invoice.not_canceled.order(:id).should eq [@open_invoice, @failed_invoice, @waiting_invoice, @paid_invoice, @refunded_invoice] }
    end

    describe "#not_paid" do
      specify { Invoice.not_paid.order(:id).should eq [@open_invoice, @failed_invoice, @waiting_invoice] }
    end

  end # Scopes

  describe "Class Methods" do

    describe ".update_pending_dates_for_first_not_paid_invoices" do
      before(:each) do
        Timecop.travel(Time.utc(2011, 4, 4, 6)) do
          @user = Factory.create(:user)

          @site1 = Factory.build(:site_not_in_trial, plan_id: @paid_plan.id, user: @user, first_paid_plan_started_at: Time.now.utc)
          @site1.prepare_pending_attributes
          @site1.save!

          Invoice.delete_all
          @invoice1 = Factory.create(:invoice, state: 'open', site: @site1, renew: false, created_at: 5.hours.ago)
          @invoice1.invoice_items << Factory.create(:plan_invoice_item, invoice: @invoice1, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice1.save!

          @invoice2 = Factory.create(:invoice, state: 'open', site: @site1, renew: false, created_at: 4.hours.ago) # fake an upgrade, should not update pending dates
          @invoice2.invoice_items << Factory.create(:plan_invoice_item, invoice: @invoice2, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice2.save!

          @invoice3 = Factory.create(:invoice, state: 'failed', site: @site1, renew: true, created_at: 3.hours.ago) # renew failed
          @invoice3.invoice_items << Factory.create(:plan_invoice_item, invoice: @invoice3, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice3.save!

          @invoice4 = Factory.create(:invoice, state: 'failed', site: @site1, renew: false, created_at: 2.hours.ago) # upgrade failed
          @invoice4.invoice_items << Factory.create(:plan_invoice_item, invoice: @invoice4, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice4.save!

          @invoice5 = Factory.create(:invoice, state: 'paid', site: @site1, created_at: 1.hour.ago) # already paid
          @invoice5.invoice_items << Factory.create(:plan_invoice_item, invoice: @invoice5, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice5.save!

          @invoice1.should eql @site1.invoices.by_date('asc').first
        end
      end
      before(:each) do
        Delayed::Job.delete_all
      end

      it "should update pending dates in the site and the plan invoice item of the invoices where renew flag == false by user" do
        @site1.pending_plan_started_at.should eq Time.utc(2011, 4, 4)
        @site1.pending_plan_cycle_started_at.should eq Time.utc(2011, 4, 4)
        @site1.pending_plan_cycle_ended_at.to_i.should eq Time.utc(2011, 5, 3).to_datetime.end_of_day.to_i

        Timecop.travel(Time.utc(2011, 4, 8)) do
          Invoice.update_pending_dates_for_first_not_paid_invoices
        end

        @invoice1.reload.invoice_items.first.started_at.should eq Time.utc(2011, 4, 8)
        @invoice1.invoice_items.first.ended_at.to_i.should eq Time.utc(2011, 5, 7).end_of_day.to_i
        @invoice2.reload.invoice_items.first.started_at.should eq Time.utc(2011, 4, 4)
        @invoice2.invoice_items.first.ended_at.to_i.should eq Time.utc(2011, 5, 3).end_of_day.to_i
        @invoice3.reload.invoice_items.first.started_at.should eq Time.utc(2011, 4, 4)
        @invoice3.invoice_items.first.ended_at.to_i.should eq Time.utc(2011, 5, 3).end_of_day.to_i
        @invoice4.reload.invoice_items.first.started_at.should eq Time.utc(2011, 4, 4)
        @invoice4.invoice_items.first.ended_at.to_i.should eq Time.utc(2011, 5, 3).end_of_day.to_i
        @invoice5.reload.invoice_items.first.started_at.should eq Time.utc(2011, 4, 4)
        @invoice5.invoice_items.first.ended_at.to_i.should eq Time.utc(2011, 5, 3).end_of_day.to_i

        @site1.reload.first_paid_plan_started_at.should eq Time.utc(2011, 4, 8)
        @site1.pending_plan_started_at.should eq Time.utc(2011, 4, 8)
        @site1.pending_plan_cycle_started_at.should eq Time.utc(2011, 4, 8)
        @site1.pending_plan_cycle_ended_at.to_i.should eq Time.utc(2011, 5, 7).to_datetime.end_of_day.to_i
      end
    end

    describe ".construct" do
      before { @paid_plan = Factory.create(:plan, cycle: "month", price: 1000) }

      describe "standard invoice" do
        before(:each) do
          @user = Factory.create(:user, billing_country: 'FR', created_at: Time.utc(2011,3,30))
          Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) do
            @site    = Factory.create(:site, user: @user, plan_id: @paid_plan.id)
            @invoice = Invoice.construct(site: @site)
          end
        end
        subject { @invoice }

        specify { subject.invoice_items.should have(1).item } # 1 plan
        specify { subject.invoice_items.all? { |ii| ii.item eq @paid_plan }.should be_true }
        specify { subject.invoice_items.all? { |ii| ii.site eq @site }.should be_true }
        specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }

        its(:invoice_items_amount) { should eq 1000 } # paid_plan.price
        its(:vat_rate)             { should eq 0.0 }
        its(:vat_amount)           { should eq 0 }
        its(:amount)               { should eq 1000 } # paid_plan.price
        its(:paid_at)              { should be_nil }
        its(:last_failed_at)       { should be_nil }
        it { should be_open }
      end

      describe "with a site upgraded" do
        context "from a paid plan" do
          before(:each) do
            @user = Factory.create(:user, billing_country: 'FR', created_at: Time.utc(2011,3,30))
            Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) do
              @site       = Factory.create(:site_with_invoice, user: @user, plan_id: @paid_plan.id)
              @paid_plan2 = Factory.create(:plan, cycle: "month", price: 3000)
              # Simulate upgrade
              @site.plan_id = @paid_plan2.id
              @invoice = Invoice.construct(site: @site)
            end
          end
          subject { @invoice }

          it { subject.invoice_items.should have(2).items }
          it { subject.invoice_items.all? { |ii| ii.site eq @site }.should be_true }
          it { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
          it { subject.invoice_items.first.item.should eq @paid_plan }
          it { subject.invoice_items.first.price.should eq 1000 }
          it { subject.invoice_items.first.amount.should eq -1000 }
          it { subject.invoice_items.second.item.should eq @paid_plan2 }
          it { subject.invoice_items.second.price.should eq 3000 }
          it { subject.invoice_items.second.amount.should eq 3000 }

          its(:invoice_items_amount) { should eq 2000 } # paid_plan2.price - paid_plan.price
          its(:vat_rate)             { should eq 0.0 }
          its(:vat_amount)           { should eq 0 }
          its(:amount)               { should eq 2000 } # paid_plan2.price - paid_plan.price
          its(:paid_at)              { should be_nil }
          its(:last_failed_at)       { should be_nil }
          it { should be_open }
        end

        context "from a free plan" do
          before(:each) do
            @user = Factory.create(:user, billing_country: 'FR', created_at: Time.utc(2011,3,30))
            Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) do
              @site      = Factory.create(:site, user: @user, plan_id: @free_plan.id)
              @paid_plan = Factory.create(:plan, cycle: "month", price: 3000)
              # Simulate upgrade
              @site.plan_id = @paid_plan.id
              @invoice = Invoice.construct(site: @site)
            end
          end
          subject { @invoice }

          specify { subject.invoice_items.should have(1).item }
          specify { subject.invoice_items.all? { |ii| ii.site eq @site }.should be_true }
          specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
          specify { subject.invoice_items.first.item.should eq @paid_plan }
          specify { subject.invoice_items.first.price.should eq 3000 }

          its(:invoice_items_amount) { should eq 3000 } # paid_plan.price
          its(:vat_rate)             { should eq 0.0 }
          its(:vat_amount)           { should eq 0 }
          its(:amount)               { should eq 3000 } # paid_plan.price
          its(:paid_at)              { should be_nil }
          its(:last_failed_at)       { should be_nil }
          it { should be_open }
        end
      end

      describe "with a site downgraded" do
        context "from a paid plan" do
          before(:each) do
            @user = Factory.create(:user, billing_country: 'FR', created_at: Time.utc(2011,3,30))
            Timecop.travel(Time.utc(2011,5,1)) do
              @site       = Factory.create(:site_with_invoice, user: @user, plan_id: @paid_plan.id)
              @paid_plan2 = Factory.create(:plan, cycle: "month", price: 500)
              # Simulate downgrade
              @site.plan_id = @paid_plan2.id
            end

            Timecop.travel(Time.utc(2011,6,1)) do
              @site.prepare_pending_attributes
              @site.save_skip_pwd
              @invoice = Invoice.construct(site: @site)
            end
          end
          subject { @invoice }

          it { subject.invoice_items.should have(1).item }
          it { subject.invoice_items.first.site.should eq @site }
          it { subject.invoice_items.first.invoice.should eq subject }
          it { subject.invoice_items.first.item.should eq @paid_plan2 }
          it { subject.invoice_items.first.price.should eq 500 }
          it { subject.invoice_items.first.amount.should eq 500 }

          its(:invoice_items_amount) { should eq 500 } # paid_plan2.price
          its(:vat_rate)             { should eq 0.0 }
          its(:vat_amount)           { should eq 0 }
          its(:amount)               { should eq 500 } # paid_plan2.price
          its(:paid_at)              { should be_nil }
          its(:last_failed_at)       { should be_nil }
          it { should be_open }
        end
      end

      describe "with a site created" do
        before(:each) do
          @user    = Factory.create(:user, billing_country: 'FR', created_at: Time.utc(2011,3,30))
          Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.day) do
            @site = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id)
            @invoice = Invoice.construct(site: @site)
          end
        end
        subject { @invoice }

        its(:invoice_items_amount) { should eq 1000 }
        its(:vat_rate)             { should eq 0.0 }
        its(:vat_amount)           { should eq 0 }
        its(:amount)               { should eq 1000 }
      end

      describe "with a Swiss user" do
        before(:each) do
          @user    = Factory.create(:user, billing_country: 'CH')
          @site = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id)
          @invoice = Invoice.construct(site: @site)
        end
        subject { @invoice }

        its(:invoice_items_amount) { should eq 1000 }
        its(:vat_rate)             { should eq 0.08 }
        its(:vat_amount)           { should eq (1000 * 0.08).round }
        its(:amount)               { should eq 1000 + (1000 * 0.08).round }
      end

      describe "with a user that has a balance" do
        context "balance < invoice amount" do
          before(:each) do
            @user    = Factory.create(:user, billing_country: 'FR', balance: 100)
            @site    = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id)
            @invoice = Invoice.construct(site: @site)
          end
          subject { @invoice }

          its(:invoice_items_amount)     { should eql 1000 }
          its(:balance_deduction_amount) { should eql 100 }
          its(:amount)                   { should eql 900 }
        end

        context "balance == invoice amount" do
          before(:each) do
            @user    = Factory.create(:user, billing_country: 'FR', balance: 1000)
            @site    = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id)
            @invoice = Invoice.construct(site: @site)
          end
          subject { @invoice }

          its(:invoice_items_amount)     { should eql 1000 }
          its(:balance_deduction_amount) { should eql 1000 }
          its(:amount)                   { should eql 0 }
        end

        context "balance > invoice amount" do
          before(:each) do
            @user    = Factory.create(:user, billing_country: 'FR', balance: 2000)
            @site    = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id)
            @invoice = Invoice.construct(site: @site)
          end
          subject { @invoice }

          its(:invoice_items_amount)     { should eql 1000 }
          its(:balance_deduction_amount) { should eql 1000 }
          its(:amount)                   { should eql 0 }
        end
      end

    end # .construct

  end # Class Methods

  describe "Instance Methods" do
    before(:each) do
      @invoice = Factory.create(:invoice)
      @paid_plan_invoice_item = Factory.create(:plan_invoice_item, invoice: @invoice, item: @paid_plan, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
      @invoice.invoice_items << @paid_plan_invoice_item

      Factory.create(:transaction, invoices: [@invoice], state: 'failed', created_at: 4.days.ago)
      @failed_transaction2 = Factory.create(:transaction, invoices: [@invoice], state: 'failed', created_at: 3.days.ago)
      @paid_transaction = Factory.create(:transaction, invoices: [@invoice], state: 'paid', created_at: 2.days.ago)
    end
    subject { @invoice }

    describe "#paid_plan_invoice_item" do
      it { subject.paid_plan_invoice_item.should eq @paid_plan_invoice_item }
    end

    describe "#paid_plan" do
      it { subject.paid_plan.should eq @paid_plan }
    end

    describe "#last_transaction" do
      it { subject.last_transaction.should eq @paid_transaction }
    end

    describe "#first_site_invoice?" do
      before { @site = Factory.create(:site) }

      it { Factory.build(:invoice).should be_first_site_invoice }
      it { subject.should be_first_site_invoice }

      context "first invoice was canceled" do
        before(:each) do
          @canceled_invoice   = Factory.create(:invoice, site: @site, state: 'canceled')
          @first_site_invoice = Factory.create(:invoice, site: @site)
        end

        it { @canceled_invoice.should_not be_first_site_invoice }
        it { @first_site_invoice.should be_first_site_invoice }
      end

      context "already one non-canceled invoice" do
        before(:each) do
          @first_site_invoice  = Factory.create(:invoice, site: @site)
          @second_site_invoice = Factory.create(:invoice, site: @site)
        end

        it { @first_site_invoice.should be_first_site_invoice }
        it { @second_site_invoice.should_not be_first_site_invoice }
      end
    end
  end # Instance Methods

end




# == Schema Information
#
# Table name: invoices
#
#  id                       :integer         not null, primary key
#  site_id                  :integer
#  reference                :string(255)
#  state                    :string(255)
#  customer_full_name       :string(255)
#  customer_email           :string(255)
#  customer_country         :string(255)
#  customer_company_name    :string(255)
#  site_hostname            :string(255)
#  amount                   :integer
#  vat_rate                 :float
#  vat_amount               :integer
#  invoice_items_amount     :integer
#  invoice_items_count      :integer         default(0)
#  transactions_count       :integer         default(0)
#  created_at               :datetime
#  updated_at               :datetime
#  paid_at                  :datetime
#  last_failed_at           :datetime
#  renew                    :boolean         default(FALSE)
#  balance_deduction_amount :integer         default(0)
#  customer_billing_address :text
#
# Indexes
#
#  index_invoices_on_reference  (reference) UNIQUE
#  index_invoices_on_site_id    (site_id)
#

