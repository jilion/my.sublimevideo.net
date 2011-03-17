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
    its(:failed_at)            { should be_nil }

    it { should be_open } # initial state
    it { should be_valid }
  end # Factory

  describe "Associations" do
    before(:all) { @invoice = Factory(:invoice) }
    subject { @invoice }

    it { should belong_to :site }
    it { should have_many :invoice_items }
    it { should have_and_belong_to_many :transactions }
  end # Associations

  describe "Scopes" do
    before(:all) do
      Invoice.delete_all
      @open_invoice   = Factory(:invoice, state: 'open', created_at: 48.hours.ago)
      @failed_invoice = Factory(:invoice, state: 'failed', created_at: 25.hours.ago)
      @paid_invoice   = Factory(:invoice, state: 'paid', created_at: 18.hours.ago)
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

    pending "Transitions" do

      describe "after_transition :on => :complete, :do => :decrement_user_remaining_discounted_months" do
        before(:each) { subject.reload.update_attribute(:state, 'open') }

        context "no remaining_discounted_months" do
          before(:each) { subject.user.reload.update_attribute(:remaining_discounted_months, 0) }

          it "should set open invoice directly to paid" do
            subject.user.remaining_discounted_months.should == 0
            subject.complete
            subject.user.remaining_discounted_months.should == 0
          end
        end

        context "a remaining_discounted_months" do
          before(:each) { subject.user.reload.update_attribute(:remaining_discounted_months, 1) }

          it "should set open invoice directly to paid" do
            subject.user.remaining_discounted_months.should == 1
            subject.complete
            subject.user.remaining_discounted_months.should == 0
          end
        end
      end

      describe "after_transition :on => :complete, :do => :update_user_invoiced_amount" do
        before(:each) { subject.reload.update_attribute(:state, 'open') }

        it "should update user.last_invoiced_amount" do
          subject.user.update_attribute(:last_invoiced_amount, 500)
          expect { subject.complete }.should change(subject.user, :last_invoiced_amount).from(500).to(10000)
        end
        it "should increment user.total_invoiced_amount" do
          subject.user.update_attribute(:total_invoiced_amount, 500)
          expect { subject.complete }.should change(subject.user, :total_invoiced_amount).from(500).to(10500)
        end
      end

      describe "after_transition  :open => :open, :do => :send_invoice_completed_email" do
        context "from open" do
          before(:each) { subject.reload.update_attribute(:state, 'open') }

          it "should send an email to invoice.user" do
            lambda { subject.complete }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.user.email]
          end

          context "with an archived user" do
            before(:each) { subject.reload.user.update_attribute(:state, 'archived') }

            it "should not send an email to the user" do
              lambda { subject.complete }.should_not change(ActionMailer::Base.deliveries, :count)
            end
          end
        end
      end

      describe "before_transition :open => :failed, :do => :delay_suspend_user" do
        context "from open" do
          before(:each) { subject.reload.update_attributes(state: 'open', attempts: Billing.max_charging_attempts + 1, charging_delayed_job_id: 1) }

          it "should delay user.suspend in Billing.days_before_suspend_user days" do
            lambda { subject.fail }.should change(Delayed::Job.where(:handler.matches => "%Class%suspend%"), :count).by(1)
            Delayed::Job.where(:handler.matches => "%Class%suspend%").first.run_at.should be_within(5).of(Billing.days_before_suspend_user.days.from_now) # seconds of tolerance
          end
        end
      end

      describe "after_transition :open => :failed, :do => :send_charging_failed_email" do
        context "from open" do
          before(:each) { subject.reload.update_attributes(state: 'open', attempts: Billing.max_charging_attempts + 1) }

          it "should send an email to invoice.user" do
            lambda { subject.fail }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.user.email]
          end
        end
      end

      describe "after_transition [:open, :failed] => :paid, :do => :unsuspend_user" do
        context "with a non-suspended user" do
          %w[open failed].each do |state|
            context "from #{state}" do
              before(:each) do
                subject.reload.update_attributes(state: state, amount: 0)
                subject.user.should_not be_suspended
              end

              it "should not delay un-suspend_user" do
                lambda { subject.send(state == 'open' ? :complete : :succeed) }.should_not change(Delayed::Job, :count)
                subject.should be_paid
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
                it "should delay un-suspend_user" do
                  lambda { subject.send(state == 'open' ? :complete : :succeed) }.should change(Delayed::Job, :count).by(1)
                  Delayed::Job.where(:handler.matches => "%Class%unsuspend%").count.should == 1
                  subject.should be_paid
                end
              end

              context "with more open invoice" do
                before(:each) do
                  Factory(:invoice, user: subject.user, state: 'failed', started_at: Time.now.utc, ended_at: Time.now.utc)
                end

                it "should not delay un-suspend_user" do
                  lambda { subject.send(state == 'open' ? :complete : :succeed) }.should_not change(Delayed::Job, :count)
                  subject.should be_paid
                end
              end
            end
          end
        end
      end

    end # Transitions

  end # State Machine

  describe "Class Methods" do

    describe ".build" do
      before(:all) do
        @paid_plan = Factory(:plan, cycle: "month", price: 1000)
      end

      describe "standard invoice" do
        before(:all) do
          @user    = Factory(:user, country: 'FR')
          @site    = Factory(:site, user: @user, plan: @paid_plan).reload
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
        its(:failed_at)            { should be_nil }
        it { should be_open }
      end

      describe "with a site upgraded" do
        context "from a paid plan" do
          before(:all) do
            @user       = Factory(:user, country: 'FR')
            @site       = Factory(:site, user: @user, plan: @paid_plan).reload
            @paid_plan2 = Factory(:plan, cycle: "month", price: 3000)
            # Simulate upgrade
            @site.plan_id = @paid_plan2.id
            # @site.instance_variable_set(:@instant_charging, true)

            @invoice = Invoice.build(site: @site)
          end
          subject { @invoice }

          specify { subject.invoice_items.size.should == 2 }
          specify { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
          specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
          specify { subject.invoice_items.first.item.should == @paid_plan }
          specify { subject.invoice_items.first.price.should == -1000 }
          specify { subject.invoice_items.second.item.should == @paid_plan2 }
          specify { subject.invoice_items.second.price.should == 3000 }

          its(:invoice_items_amount) { should == 2000 } # paid_plan2.price - paid_plan.price
          its(:vat_rate)             { should == 0.0 }
          its(:vat_amount)           { should == 0 }
          its(:amount)               { should == 2000 } # paid_plan2.price - paid_plan.price
          its(:paid_at)              { should be_nil }
          its(:failed_at)            { should be_nil }
          it { should be_open }
        end
        
        %w[dev beta].each do |plan|
          context "from a #{plan} plan" do
            before(:all) do
              @user      = Factory(:user, country: 'FR')
              @site      = Factory(:site, user: @user, plan: instance_variable_get("@#{plan}_plan")).reload
              @paid_plan = Factory(:plan, cycle: "month", price: 3000)
              # Simulate upgrade
              @site.plan_id = @paid_plan.id
              # @site.instance_variable_set(:@instant_charging, true)

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
            its(:failed_at)            { should be_nil }
            it { should be_open }
          end
        end
      end

      describe "with a Swiss user" do
        before(:all) do
          @user    = Factory(:user, country: 'CH')
          @site    = Factory(:site, user: @user, plan: @paid_plan).reload
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

      describe "with a user with a discount" do
        before(:all) do
          @user    = Factory(:user, country: 'FR', remaining_discounted_months: 1)
          @site    = Factory(:site, user: @user, plan: @paid_plan).reload
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

end



# == Schema Information
#
# Table name: invoices
#
#  id                      :integer         not null, primary key
#  site_id                 :integer
#  reference               :string(255)
#  state                   :string(255)
#  amount                  :integer
#  vat_rate                :float
#  vat_amount              :integer
#  discount_rate           :float
#  discount_amount         :integer
#  invoice_items_amount    :integer
#  charging_delayed_job_id :integer
#  invoice_items_count     :integer         default(0)
#  transactions_count      :integer         default(0)
#  created_at              :datetime
#  updated_at              :datetime
#  paid_at                 :datetime
#  failed_at               :datetime
#
# Indexes
#
#  index_invoices_on_site_id  (site_id)
#

