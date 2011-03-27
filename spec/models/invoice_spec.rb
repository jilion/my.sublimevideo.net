require 'spec_helper'

describe Invoice do

  describe "Factory" do
    before(:all) { @invoice = Factory(:invoice) }
    subject { @invoice }

    its(:site)                 { should be_present }
    its(:reference)            { should =~ /^[a-z1-9]{8}$/ }
    its(:invoice_items_amount) { should == 10000 }
    its(:amount)               { should == 10000 }
    its(:paid_at)              { should be_nil }
    its(:last_failed_at)       { should be_nil }

    it { should be_open } # initial state
    it { should be_valid }
  end # Factory

  describe "Associations" do
    before(:all) { @invoice = Factory(:invoice) }
    subject { @invoice }

    it { should belong_to :site }
    it { should have_one :user }
    it { should have_many :invoice_items }
    it { should have_and_belong_to_many :transactions }
  end # Associations

  describe "Validations" do
    before(:all) { @invoice = Factory(:invoice) }
    subject { @invoice }

    it { should validate_presence_of(:site) }
    it { should validate_presence_of(:invoice_items_amount) }
    it { should validate_presence_of(:vat_rate) }
    it { should validate_presence_of(:vat_amount) }
    it { should validate_presence_of(:amount) }

    it { should validate_numericality_of(:invoice_items_amount) }
    it { should validate_numericality_of(:vat_rate) }
    it { should validate_numericality_of(:vat_amount) }
    it { should validate_numericality_of(:amount) }
  end # Validations

  describe "State Machine" do
    before(:all) { @invoice = Factory(:invoice) }
    subject { @invoice }

    describe "Initial state" do
      it { should be_open }
    end

    describe "Transitions" do
      describe "before_transition :on => :succeed, :do => :set_paid_at" do
        subject { @invoice.reload }
        it "should set paid_at" do
          subject.paid_at.should be_nil
          subject.succeed
          subject.paid_at.should be_present
        end
      end

      describe "before_transition :on => :fail, :do => :set_last_failed_at" do
        subject { @invoice.reload }
        it "should set last_failed_at" do
          subject.last_failed_at.should be_nil
          subject.fail
          subject.last_failed_at.should be_present
        end
      end

      describe "after_transition :on => :succeed, :do => :apply_pending_site_plan_changes" do
        it "should call #apply_pending_plan_changes on the site" do
          site = Factory(:site)
          site.should_receive(:apply_pending_plan_changes)
          Factory(:invoice, site: site).succeed
        end
      end

      describe "after_transition :on => :succeed, :do => :update_user_invoiced_amount" do
        subject { @invoice.reload }

        it "should update user.last_invoiced_amount" do
          subject.user.update_attribute(:last_invoiced_amount, 500)
          expect { subject.succeed }.should change(subject.user.reload, :last_invoiced_amount).from(500).to(10000)
        end

        it "should increment user.total_invoiced_amount" do
          subject.user.update_attribute(:total_invoiced_amount, 500)
          expect { subject.succeed }.should change(subject.user.reload, :total_invoiced_amount).from(500).to(10500)
        end

        it "should save user" do
          old_user_last_invoiced_amount = subject.user.last_invoiced_amount
          old_user_total_invoiced_amount = subject.user.total_invoiced_amount
          subject.succeed!
          subject.user.reload
          subject.user.last_invoiced_amount.should_not == old_user_last_invoiced_amount
          subject.user.total_invoiced_amount.should_not == old_user_total_invoiced_amount
        end
      end

      describe "after_transition :on => :succeed, :do => :unsuspend_user" do
        subject { @invoice.reload }

        context "with a non-suspended user" do
          %w[open failed].each do |state|
            context "from #{state}" do
              before(:each) do
                subject.reload.update_attributes(state: state, amount: 0)
                subject.user.should be_active
              end

              it "should not un-suspend_user" do
                subject.succeed
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
                  subject.succeed
                  subject.should be_paid
                  subject.user.should be_active
                end
              end

              context "with more failed invoice" do
                before(:each) do
                  Factory(:invoice, site: Factory(:site, user: subject.user), state: 'failed')
                end

                it "should not delay un-suspend_user" do
                  subject.succeed
                  subject.should be_paid
                  subject.user.should be_suspended
                end
              end
            end
          end
        end
      end
    end # Transitions

  end # State Machine

  describe "Callbacks" do
    describe "#before_create" do
      describe "#set_customer_infos" do
        subject { Factory(:invoice) }

        it { subject.customer_full_name.should == subject.user.full_name }
        it { subject.customer_email.should     == subject.user.email }
        it { subject.customer_country.should   == subject.user.country }
        it { subject.customer_company_name.should   == subject.user.company_name }
      end
    end
  end

  describe "Scopes" do
    before(:all) do
      Invoice.delete_all
      @site = Factory(:site, plan_id: @dev_plan.id)
      @open_invoice   = Factory(:invoice, site: @site, state: 'open', created_at: 48.hours.ago)
      @failed_invoice = Factory(:invoice, site: @site, state: 'failed', created_at: 25.hours.ago)
      @paid_invoice   = Factory(:invoice, site: @site, state: 'paid', created_at: 18.hours.ago)
    end

    describe "#between" do
      specify { Invoice.between(24.hours.ago, 12.hours.ago).all.should == [@paid_invoice] }
    end

    describe "#open" do
      specify { Invoice.open.all.should == [@open_invoice] }
    end

    describe "#failed" do
      specify { Invoice.failed.all.should == [@failed_invoice] }
    end

    describe "#open_or_failed" do
      specify { Invoice.open_or_failed.all.should == [@open_invoice, @failed_invoice] }
    end

    describe "#paid" do
      specify { Invoice.paid.all.should == [@paid_invoice] }
    end

  end # Scopes

  describe "Class Methods" do

    describe ".build" do
      before(:all) do
        @paid_plan = Factory(:plan, cycle: "month", price: 1000)
      end

      describe "standard invoice" do
        before(:all) do
          @user    = Factory(:user, country: 'FR')
          @site    = Factory(:site, user: @user, plan_id: @paid_plan.id)
          @invoice = Invoice.build(site: @site)
        end
        subject { @invoice }

        specify { subject.invoice_items.size.should == 1 } # 1 plan
        specify { subject.invoice_items.all? { |ii| ii.item == @paid_plan }.should be_true }
        specify { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
        specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }

        its(:invoice_items_amount) { should == 1000 } # paid_plan.price
        its(:vat_rate)             { should == 0.0 }
        its(:vat_amount)           { should == 0 }
        its(:amount)               { should == 1000 } # paid_plan.price
        its(:paid_at)              { should be_nil }
        its(:last_failed_at)       { should be_nil }
        it { should be_open }
      end

      describe "with a site upgraded" do
        context "from a paid plan" do
          before(:all) do
            @user       = Factory(:user, country: 'FR')
            @site       = Factory(:site, user: @user, plan_id: @paid_plan.id)
            @paid_plan2 = Factory(:plan, cycle: "month", price: 3000)
            # Simulate upgrade
            @site.plan_id = @paid_plan2.id
            @invoice = Invoice.build(site: @site)
          end
          subject { @invoice }

          specify { subject.invoice_items.size.should == 2 }
          specify { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
          specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
          specify { subject.invoice_items.first.item.should == @paid_plan }
          specify { subject.invoice_items.first.price.should == 1000 }
          specify { subject.invoice_items.first.amount.should == -1000 }
          specify { subject.invoice_items.second.item.should == @paid_plan2 }
          specify { subject.invoice_items.second.price.should == 3000 }
          specify { subject.invoice_items.second.amount.should == 3000 }

          its(:invoice_items_amount) { should == 2000 } # paid_plan2.price - paid_plan.price
          its(:vat_rate)             { should == 0.0 }
          its(:vat_amount)           { should == 0 }
          its(:amount)               { should == 2000 } # paid_plan2.price - paid_plan.price
          its(:paid_at)              { should be_nil }
          its(:last_failed_at)       { should be_nil }
          it { should be_open }
        end

        %w[dev beta].each do |plan|
          context "from a #{plan} plan" do
            before(:all) do
              @user      = Factory(:user, country: 'FR')
              @site      = Factory(:site, user: @user, plan_id: instance_variable_get("@#{plan}_plan").id)
              @paid_plan = Factory(:plan, cycle: "month", price: 3000)
              # Simulate upgrade
              @site.plan_id = @paid_plan.id
              @invoice = Invoice.build(site: @site)
            end
            subject { @invoice }

            specify { subject.invoice_items.size.should == 1 }
            specify { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
            specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
            specify { subject.invoice_items.first.item.should == @paid_plan }
            specify { subject.invoice_items.first.price.should == 3000 }

            its(:invoice_items_amount) { should == 3000 } # paid_plan.price
            its(:vat_rate)             { should == 0.0 }
            its(:vat_amount)           { should == 0 }
            its(:amount)               { should == 3000 } # paid_plan.price
            its(:paid_at)              { should be_nil }
            its(:last_failed_at)       { should be_nil }
            it { should be_open }
          end
        end
      end

      describe "with a Swiss user" do
        before(:all) do
          @user    = Factory(:user, country: 'CH')
          @site    = Factory(:site, user: @user, plan_id: @paid_plan.id)
          @invoice = Invoice.build(site: @site)
        end
        subject { @invoice }

        its(:invoice_items_amount) { should == 1000 }
        its(:discount_rate)        { should == 0.0 }
        its(:discount_amount)      { should == 0.0 }
        its(:vat_rate)             { should == 0.08 }
        its(:vat_amount)           { should == (1000 * 0.08).round }
        its(:amount)               { should == 1000 + (1000 * 0.08).round }
      end

      pending "with a user with a discount" do
        before(:all) do
          @user    = Factory(:user, country: 'FR')
          @site    = Factory(:site, user: @user, plan_id: @paid_plan.id).reload
          @invoice = Invoice.build(site: @site)
        end
        subject { @invoice }

        its(:invoice_items_amount) { should == 1000 }
        its(:discount_rate)        { should == Billing.beta_discount_rate }
        its(:discount_amount)      { should == (Billing.beta_discount_rate * 1000).round }
        its(:vat_rate)             { should == 0.0 }
        its(:vat_amount)           { should == 0 }
        its(:amount)               { should == 1000 - (Billing.beta_discount_rate * 1000).round }
      end
    end # .build

  end # Class Methods

  describe "Instance Methods" do
    before(:all) do
      @invoice = Factory(:invoice)
      Factory(:transaction, invoices: [@invoice], state: 'failed', created_at: 4.days.ago)
      @failed_transaction2 = Factory(:transaction, invoices: [@invoice], state: 'failed', created_at: 3.days.ago)
      @paid_transaction = Factory(:transaction, invoices: [@invoice], state: 'paid', created_at: 2.days.ago)
    end
    subject { @invoice }

    describe "#last_transaction" do
      it { subject.last_transaction.should == @paid_transaction }
    end

    describe "#last_failed_transaction" do
      it { subject.last_failed_transaction.should == @failed_transaction2 }
    end

  end # Instance Methods

end




# == Schema Information
#
# Table name: invoices
#
#  id                    :integer         not null, primary key
#  site_id               :integer
#  reference             :string(255)
#  state                 :string(255)
#  customer_full_name    :string(255)
#  customer_email        :string(255)
#  customer_country      :string(255)
#  customer_company_name :string(255)
#  amount                :integer
#  vat_rate              :float
#  vat_amount            :integer
#  discount_rate         :float
#  discount_amount       :integer
#  invoice_items_amount  :integer
#  invoice_items_count   :integer         default(0)
#  transactions_count    :integer         default(0)
#  created_at            :datetime
#  updated_at            :datetime
#  paid_at               :datetime
#  last_failed_at        :datetime
#
# Indexes
#
#  index_invoices_on_reference  (reference) UNIQUE
#  index_invoices_on_site_id    (site_id)
#

