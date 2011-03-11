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
      @open_invoice   = Factory(:invoice, state: 'open', created_at: 48.hours.ago)
      @unpaid_invoice = Factory(:invoice, state: 'unpaid', created_at: 36.hours.ago)
      @failed_invoice = Factory(:invoice, state: 'failed', created_at: 25.hours.ago)
      @paid_invoice   = Factory(:invoice, state: 'paid', created_at: 18.hours.ago)
    end

    describe "#between" do
      specify { Invoice.between(24.hours.ago, 12.hours.ago).all.should == [@paid_invoice] }
    end

    describe "#failed" do
      specify { Invoice.failed.all.should == [@failed_invoice] }
    end

    describe "#unpaid_or_failed" do
      specify { Invoice.unpaid_or_failed.all.should == [@unpaid_invoice, @failed_invoice] }
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

    describe "Events" do

      describe "#complete" do
        context "from open state" do
          before(:each) { subject.reload.update_attribute(:state, 'open') }

          it "should set open invoice to unpaid if amount < 0" do
            subject.reload.amount = -1
            subject.complete
            subject.should be_unpaid
          end
          it "should set open invoice to unpaid if amount < 0" do
            subject.reload.amount = 1
            subject.complete
            subject.should be_unpaid
          end
        end
      end

    end # Events

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

      describe "after_transition  :open => :unpaid, :do => :send_invoice_completed_email" do
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

      describe "before_transition :unpaid => :failed, :do => :delay_suspend_user" do
        context "from unpaid" do
          before(:each) { subject.reload.update_attributes(state: 'unpaid', attempts: Billing.max_charging_attempts + 1, charging_delayed_job_id: 1) }

          it "should delay user.suspend in Billing.days_before_suspend_user days" do
            lambda { subject.fail }.should change(Delayed::Job.where(:handler.matches => "%Class%suspend%"), :count).by(1)
            Delayed::Job.where(:handler.matches => "%Class%suspend%").first.run_at.should be_within(5).of(Billing.days_before_suspend_user.days.from_now) # seconds of tolerance
          end
        end
      end

      describe "after_transition :unpaid => :failed, :do => :send_charging_failed_email" do
        context "from unpaid" do
          before(:each) { subject.reload.update_attributes(state: 'unpaid', attempts: Billing.max_charging_attempts + 1) }

          it "should send an email to invoice.user" do
            lambda { subject.fail }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.user.email]
          end
        end
      end

      describe "after_transition [:open, :unpaid, :failed] => :paid, :do => :unsuspend_user" do
        context "with a non-suspended user" do
          %w[open unpaid failed].each do |state|
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
          %w[open unpaid failed].each do |state|
            context "from #{state}" do
              before(:each) do
                subject.reload.update_attributes(state: state, amount: 0)
                subject.user.update_attribute(:state, 'suspended')
                subject.user.should be_suspended
              end

              context "with no more unpaid invoice" do
                it "should delay un-suspend_user" do
                  lambda { subject.send(state == 'open' ? :complete : :succeed) }.should change(Delayed::Job, :count).by(1)
                  Delayed::Job.where(:handler.matches => "%Class%unsuspend%").count.should == 1
                  subject.should be_paid
                end
              end

              context "with more unpaid invoice" do
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

    describe ".renew_active_sites_and_create_invoices" do
      before(:all) do
        Site.delete_all
        @plan1 = Factory(:plan, cycle: "month")
        @plan2 = Factory(:plan, cycle: "month")

        # to be renewed
        Timecop.travel(Time.utc(2010,2,28)) do
          @site1 = Factory(:site, plan: @plan1)
          @site2 = Factory(:site, plan: @plan1, next_cycle_plan: @plan2)
          @site1.plan_cycle_ended_at.should == Time.utc(2010,3,27).to_datetime.end_of_day
          @site2.plan_cycle_ended_at.should == Time.utc(2010,3,27).to_datetime.end_of_day
        end

        # not to be renewed
        Timecop.travel(Time.utc(2010,3,2)) do
          @site3 = Factory(:site, plan: @plan1)
          @site4 = Factory(:site, plan: @plan1, next_cycle_plan: @plan2)
          @site3.plan_cycle_ended_at.should == Time.utc(2010,4,1).to_datetime.end_of_day
          @site4.plan_cycle_ended_at.should == Time.utc(2010,4,1).to_datetime.end_of_day
        end
      end
      before(:each) do
        Delayed::Job.delete_all
        Timecop.travel(Time.utc(2010,3,30,1)) do
          Invoice.renew_active_sites_and_create_invoices
        end
      end

      it "should update site that need to be renewed" do
        @site1.reload.plan_cycle_ended_at.should == Time.utc(2010,4,27).to_datetime.end_of_day
        @site2.reload.plan_cycle_ended_at.should == Time.utc(2010,4,27).to_datetime.end_of_day

        @site3.reload.plan_cycle_ended_at.should == Time.utc(2010,4,1).to_datetime.end_of_day
        @site4.reload.plan_cycle_ended_at.should == Time.utc(2010,4,1).to_datetime.end_of_day
      end

      it "should delay create invoice for sites that need to be renewed" do
        djs = Delayed::Job.where(:handler.matches => "%complete_invoice%")
        djs.size.should == 2
        YAML.load(djs.first.handler)['args'][0].to_i.should == @site1.id
        YAML.load(djs.second.handler)['args'][0].to_i.should == @site2.id
        @site1.invoices.should be_empty
        @site2.invoices.should be_empty

        Timecop.travel(Time.utc(2010,3,30,2)) do
          @worker.work_off
        end
        Delayed::Job.where(:handler.matches => "%complete_invoice%").should be_empty

        @site1.reload.invoices.size.should == 1
        @site2.reload.invoices.size.should == 1
        @site3.reload.invoices.should be_empty
        @site4.reload.invoices.should be_empty
      end

      it "should delay charge_unpaid_and_failed_invoices for the day after" do
        djs = Delayed::Job.where(:handler.matches => "%renew_active_sites_and_create_invoices%")
        djs.size.should == 1
        djs.first.run_at.to_i.should == Time.utc(2010,3,31).midnight.to_i
      end


      context "with a failing save!" do
        before(:each) do
          @site1.stub(:save!).and_raise(ActiveRecord::RecordNotSaved)
          @site2.stub(:save!).and_raise(ActiveRecord::RecordNotSaved)
          Delayed::Job.delete_all
          Timecop.travel(Time.utc(2010,3,30,1)) do
            Invoice.renew_active_sites_and_create_invoices
          end
        end

        it "should return without delaying the invoices creation if save! fails" do
          Delayed::Job.where(:handler.matches => "%complete_invoice%").should be_empty
        end
      end

    end # .renew_active_sites_and_create_invoices

    describe ".build" do
      before(:all) do
        @plan1  = Factory(:plan, cycle: "month", price: 1000, player_hits: 2000)
        @user   = Factory(:user, country: 'FR')
        Timecop.travel(Time.utc(2010,2).beginning_of_month) do
          @site = Factory(:site, user: @user, plan: @plan1)
        end
      end
      before(:each) do
        player_hits = { main_player_hits: 1500 }
        Factory(:site_usage, player_hits.merge(site_id: @site.id, day: Time.utc(2010,1,15).midnight))
        Factory(:site_usage, player_hits.merge(site_id: @site.id, day: Time.utc(2010,2,1).midnight))
        Factory(:site_usage, player_hits.merge(site_id: @site.id, day: Time.utc(2010,2,20).midnight))
        Factory(:site_usage, player_hits.merge(site_id: @site.id, day: Time.utc(2010,3,1).midnight))
      end
      subject { Invoice.build(site: @site) }

      specify { subject.invoice_items.size.should == 1 } # 1 plan
      specify do
        invoice_items_items = subject.invoice_items.map(&:item)
        invoice_items_items.should include(@plan1)
        invoice_items_items.should include(@plan1)
      end
      specify { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
      specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }

      its(:invoice_items_amount) { should == 1000 } # plan.price
      its(:vat_rate)             { should == 0.0 }
      its(:vat_amount)           { should == 0 }
      its(:amount)               { should == 1000 } # plan.price
      its(:paid_at)              { should be_nil }
      its(:failed_at)            { should be_nil }
      it { should be_open }

      context "with a Swiss user" do
        before(:each) { @user.reload.update_attribute(:country, 'CH') }

        its(:invoice_items_amount) { should == 1000 }
        its(:discount_rate)        { should == 0.0 }
        its(:discount_amount)      { should == 0.0 }
        its(:vat_rate)             { should == 0.08 }
        its(:vat_amount)           { should == (1000 * 0.08).round }
        its(:amount)               { should == 1000 + (1000 * 0.08).round }

        describe "user has a discount" do
          before(:each) { @user.reload.update_attribute(:remaining_discounted_months, 1) }

          its(:invoice_items_amount) { should == 1000 }
          its(:discount_rate)        { should == Billing.beta_discount_rate }
          it "discount_amount" do
            subject.discount_amount.should == (Billing.beta_discount_rate * subject.invoice_items_amount).round
          end
          its(:vat_rate)             { should == 0.08 }
          it "vat_amount" do
            subject.vat_amount.should == ((subject.invoice_items_amount - subject.discount_amount) * 0.08).round
          end
          it "amount" do
            subject.amount.should == subject.invoice_items_amount - subject.discount_amount + subject.vat_amount
          end
        end
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

