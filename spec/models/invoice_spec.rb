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

      pending "after_transition :on => :succeed, :do => :push_new_revenue" do
        subject { Factory(:invoice, invoice_items: [Factory(:plan_invoice_item)]) }
        
        it "should delay on Ding class" do
          Ding.should_receive(:delay)
          subject.succeed
        end
        
        it "should send a ding!" do
          expect { subject.succeed! }.to change(Delayed::Job, :count)
          # puts Delayed::Job.all.map(&:name).inspect
          djs = Delayed::Job.where(:handler.matches => "%plan_added%")
          djs.count.should == 1
          djs.first.name.should == 'Class#plan_added'
          YAML.load(djs.first.handler)['args'][0].should == subject.invoice_items.item.first.title
          YAML.load(djs.first.handler)['args'][1].should == subject.invoice_items.item.first.cycle
          YAML.load(djs.first.handler)['args'][2].should == subject.amount
        end
      end

    end # Transitions

  end # State Machine

  describe "Callbacks" do
    describe "#before_validation, on: create" do
      before(:all) { @invoice = Factory(:invoice) }
      subject { @invoice }

      describe "#set_customer_infos" do
        its(:customer_full_name)    { should == @invoice.user.full_name }
        its(:customer_email)        { should == @invoice.user.email }
        its(:customer_country)      { should == @invoice.user.country }
        its(:customer_company_name) { should == @invoice.user.company_name }
      end

      describe "#set_site_infos" do
        its(:site_hostname)         { should == @invoice.site.hostname }
      end
    end
  end

  describe "Scopes" do
    before(:all) do
      Invoice.delete_all
      @site             = Factory(:site, plan_id: @paid_plan.id, refunded_at: nil)
      @refunded_site    = Factory(:site, plan_id: @paid_plan.id, refunded_at: Time.now.utc)
      @open_invoice     = Factory(:invoice, site: @site, state: 'open', created_at: 48.hours.ago)
      @failed_invoice   = Factory(:invoice, site: @site, state: 'failed', created_at: 25.hours.ago)
      @waiting_invoice  = Factory(:invoice, site: @site, state: 'waiting', created_at: 18.hours.ago)
      @paid_invoice     = Factory(:invoice, site: @site, state: 'paid', created_at: 16.hours.ago)
      @refunded_invoice = Factory(:invoice, site: @refunded_site, state: 'paid', created_at: 14.hours.ago)
    end

    describe "#between" do
      specify { Invoice.between(24.hours.ago, 15.hours.ago).all.should == [@waiting_invoice, @paid_invoice] }
    end

    describe "#open" do
      specify { Invoice.open.all.should == [@open_invoice] }
    end

    describe "#failed" do
      specify { Invoice.failed.all.should == [@failed_invoice] }
    end

    describe "#waiting" do
      specify { Invoice.waiting.all.should == [@waiting_invoice] }
    end

    describe "#open_or_failed" do
      specify { Invoice.open_or_failed.all.should == [@open_invoice, @failed_invoice] }
    end

    describe "#paid" do
      specify { Invoice.paid.all.should == [@paid_invoice] }
    end

    describe "#refunded" do
      specify { Invoice.refunded.all.should == [@refunded_invoice] }
    end

  end # Scopes

  describe "Class Methods" do

    describe ".update_pending_dates_for_non_renew_and_not_paid_invoices" do
      before(:all) do
        Timecop.travel(Time.utc(2011, 4, 4)) do
          @user = Factory(:user)
          @site1 = Factory(:site, user: @user)

          @site1 = Factory.build(:new_site, plan_id: @paid_plan.id, user: @user)
          @site1.pend_plan_changes
          @site1.save!
          @site2 = Factory.build(:new_site, plan_id: @paid_plan.id, user: @user)
          @site2.pend_plan_changes
          @site2.save!
          @site3 = Factory.build(:new_site, plan_id: @paid_plan.id, user: @user)
          @site3.pend_plan_changes
          @site3.save!
          @site4 = Factory.build(:new_site, plan_id: @paid_plan.id, user: @user)
          @site4.pend_plan_changes
          @site4.save!
          @site5 = Factory.build(:new_site, plan_id: @paid_plan.id, user: @user)
          @site5.pend_plan_changes
          @site5.save!

          Invoice.delete_all
          @invoice1 = Factory(:invoice, state: 'open', site: @site1, renew: true)
          @invoice1.invoice_items << Factory(:plan_invoice_item, invoice: @invoice1, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice1.save!
          @invoice2 = Factory(:invoice, state: 'open', site: @site2, renew: false)
          @invoice2.invoice_items << Factory(:plan_invoice_item, invoice: @invoice2, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice2.save!
          @invoice3 = Factory(:invoice, state: 'failed', site: @site3, renew: true)
          @invoice3.invoice_items << Factory(:plan_invoice_item, invoice: @invoice3, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice3.save!
          @invoice4 = Factory(:invoice, state: 'failed', site: @site4, renew: false)
          @invoice4.invoice_items << Factory(:plan_invoice_item, invoice: @invoice4, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice4.save!
          @invoice5 = Factory(:invoice, state: 'paid', site: @site5)
          @invoice5.invoice_items << Factory(:plan_invoice_item, invoice: @invoice5, started_at: Time.utc(2011, 4, 4), ended_at: Time.utc(2011, 5, 3).end_of_day)
          @invoice5.save!
        end
      end
      before(:each) do
        Delayed::Job.delete_all
      end

      it "should update pending dates in the site and the plan invoice item of the invoices where renew flag == false by user" do
        Timecop.travel(Time.utc(2011, 4, 8)) do
          Invoice.update_pending_dates_for_non_renew_and_not_paid_invoices
        end

        @invoice1.reload.invoice_items.first.started_at.should == Time.utc(2011, 4, 4)
        @invoice1.invoice_items.first.ended_at.to_i.should == Time.utc(2011, 5, 3).end_of_day.to_i
        @site1.reload.pending_plan_started_at.should == Time.utc(2011, 4, 4)
        @site1.pending_plan_cycle_started_at.should == Time.utc(2011, 4, 4)
        @site1.pending_plan_cycle_ended_at.to_i.should == Time.utc(2011, 5, 3).to_datetime.end_of_day.to_i

        @invoice2.reload.invoice_items.first.started_at.should == Time.utc(2011, 4, 8)
        @invoice2.invoice_items.first.ended_at.to_i.should == Time.utc(2011, 5, 7).end_of_day.to_i
        @site2.reload.pending_plan_started_at.should == Time.utc(2011, 4, 8)
        @site2.pending_plan_cycle_started_at.should == Time.utc(2011, 4, 8)
        @site2.pending_plan_cycle_ended_at.to_i.should == Time.utc(2011, 5, 7).to_datetime.end_of_day.to_i

        @invoice3.reload.invoice_items.first.started_at.should == Time.utc(2011, 4, 4)
        @invoice3.invoice_items.first.ended_at.to_i.should == Time.utc(2011, 5, 3).end_of_day.to_i
        @site3.reload.pending_plan_started_at.should == Time.utc(2011, 4, 4)
        @site3.pending_plan_cycle_started_at.should == Time.utc(2011, 4, 4)
        @site3.pending_plan_cycle_ended_at.to_i.should == Time.utc(2011, 5, 3).to_datetime.end_of_day.to_i

        @invoice4.reload.invoice_items.first.started_at.should == Time.utc(2011, 4, 8)
        @invoice4.invoice_items.first.ended_at.to_i.should == Time.utc(2011, 5, 7).end_of_day.to_i
        @site4.reload.pending_plan_started_at.should == Time.utc(2011, 4, 8)
        @site4.pending_plan_cycle_started_at.should == Time.utc(2011, 4, 8)
        @site4.pending_plan_cycle_ended_at.to_i.should == Time.utc(2011, 5, 7).to_datetime.end_of_day.to_i

        @invoice5.reload.invoice_items.first.started_at.should == Time.utc(2011, 4, 4)
        @invoice5.invoice_items.first.ended_at.to_i.should == Time.utc(2011, 5, 3).end_of_day.to_i
        @site5.reload.pending_plan_started_at.should == Time.utc(2011, 4, 4)
        @site5.pending_plan_cycle_started_at.should == Time.utc(2011, 4, 4)
        @site5.pending_plan_cycle_ended_at.to_i.should == Time.utc(2011, 5, 3).to_datetime.end_of_day.to_i
      end

      it "should delay update_pending_dates_for_non_renew_open_or_failed_invoices for the day after" do
        Delayed::Job.all.select { |dj| dj.name == "Class#update_pending_dates_for_non_renew_and_not_paid_invoices" }.count.should == 0
        Invoice.update_pending_dates_for_non_renew_and_not_paid_invoices
        djs = Delayed::Job.all
        djs.select { |dj| dj.name == "Class#update_pending_dates_for_non_renew_and_not_paid_invoices" }.count.should == 1
        djs.select { |dj| dj.name == "Class#update_pending_dates_for_non_renew_and_not_paid_invoices" }.first.run_at.should == Time.now.utc.tomorrow.midnight
      end
    end

    describe ".build" do
      before(:all) do
        @paid_plan = Factory(:plan, cycle: "month", price: 1000)
      end

      describe "standard invoice" do
        context "before beta discount end" do
          before(:all) do
            @user    = Factory(:user, country: 'FR', created_at: Time.utc(2010,10,10))
            Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.hour) do
              @site    = Factory(:site, user: @user, plan_id: @paid_plan.id)
              @invoice = Invoice.build(site: @site)
            end
          end
          subject { @invoice }

          specify { subject.invoice_items.size.should == 1 } # 1 plan
          specify { subject.invoice_items.all? { |ii| ii.item == @paid_plan }.should be_true }
          specify { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
          specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }

          its(:invoice_items_amount) { should == 800 } # paid_plan.price
          its(:vat_rate)             { should == 0.0 }
          its(:vat_amount)           { should == 0 }
          its(:amount)               { should == 800 } # paid_plan.price
          its(:paid_at)              { should be_nil }
          its(:last_failed_at)       { should be_nil }
          it { should be_open }
        end

        context "after beta discount end" do
          before(:all) do
            @user    = Factory(:user, country: 'FR', created_at: Time.utc(2011,3,30))
            Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.hour) do
              @site    = Factory(:site, user: @user, plan_id: @paid_plan.id)
              @invoice = Invoice.build(site: @site)
            end
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
      end

      describe "with a site upgraded" do
        context "from a paid plan before beta discount end" do
          before(:all) do
            @user       = Factory(:user, country: 'FR', created_at: Time.utc(2010,10,10))
            Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.hour) do
              @site       = Factory(:site_with_invoice, user: @user, plan_id: @paid_plan.id)
              @paid_plan2 = Factory(:plan, cycle: "month", price: 3000)
              # Simulate upgrade
              @site.plan_id = @paid_plan2.id
              @invoice = Invoice.build(site: @site)
            end
          end
          subject { @invoice }

          it { subject.invoice_items.size.should == 2 }
          it { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
          it { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
          it { subject.invoice_items.first.item.should == @paid_plan }
          it { subject.invoice_items.first.price.should == 800 }
          it { subject.invoice_items.first.amount.should == -800 }
          it { subject.invoice_items.second.item.should == @paid_plan2 }
          it { subject.invoice_items.second.price.should == 2400 }
          it { subject.invoice_items.second.amount.should == 2400 }

          its(:invoice_items_amount) { should == 1600 } # paid_plan2.price - paid_plan.price
          its(:vat_rate)             { should == 0.0 }
          its(:vat_amount)           { should == 0 }
          its(:amount)               { should == 1600 } # paid_plan2.price - paid_plan.price
          its(:paid_at)              { should be_nil }
          its(:last_failed_at)       { should be_nil }
          it { should be_open }
        end
        context "from a paid plan after beta discount end" do
          before(:all) do
            @user       = Factory(:user, country: 'FR', created_at: Time.utc(2011,3,30))
            Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.hour) do
              @site       = Factory(:site_with_invoice, user: @user, plan_id: @paid_plan.id)
              @paid_plan2 = Factory(:plan, cycle: "month", price: 3000)
              # Simulate upgrade
              @site.plan_id = @paid_plan2.id
              @invoice = Invoice.build(site: @site)
            end
          end
          subject { @invoice }

          it { subject.invoice_items.size.should == 2 }
          it { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
          it { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
          it { subject.invoice_items.first.item.should == @paid_plan }
          it { subject.invoice_items.first.price.should == 1000 }
          it { subject.invoice_items.first.amount.should == -1000 }
          it { subject.invoice_items.second.item.should == @paid_plan2 }
          it { subject.invoice_items.second.price.should == 3000 }
          it { subject.invoice_items.second.amount.should == 3000 }

          its(:invoice_items_amount) { should == 2000 } # paid_plan2.price - paid_plan.price
          its(:vat_rate)             { should == 0.0 }
          its(:vat_amount)           { should == 0 }
          its(:amount)               { should == 2000 } # paid_plan2.price - paid_plan.price
          its(:paid_at)              { should be_nil }
          its(:last_failed_at)       { should be_nil }
          it { should be_open }
        end

        %w[dev beta].each do |plan|
          context "from a #{plan} plan before beta discount end" do
            before(:all) do
              @user      = Factory(:user, country: 'FR', created_at: Time.utc(2010,10,10))
              Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.hour) do
                @site      = Factory(:site, user: @user, plan_id: instance_variable_get("@#{plan}_plan").id)
                @paid_plan = Factory(:plan, cycle: "month", price: 3000)
                # Simulate upgrade
                @site.plan_id = @paid_plan.id
                @invoice = Invoice.build(site: @site)
              end
            end
            subject { @invoice }

            it { subject.invoice_items.size.should == 1 }
            it { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
            it { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
            it { subject.invoice_items.first.item.should == @paid_plan }
            it { subject.invoice_items.first.price.should == 2400 }

            its(:invoice_items_amount) { should == 2400 } # paid_plan.price
            its(:vat_rate)             { should == 0.0 }
            its(:vat_amount)           { should == 0 }
            its(:amount)               { should == 2400 } # paid_plan.price
            its(:paid_at)              { should be_nil }
            its(:last_failed_at)       { should be_nil }
            it { should be_open }
          end
        end

        %w[dev beta].each do |plan|
          context "from a #{plan} plan after beta discount end" do
            before(:all) do
              @user      = Factory(:user, country: 'FR', created_at: Time.utc(2011,3,30))
              Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.hour) do
                @site      = Factory(:site, user: @user, plan_id: instance_variable_get("@#{plan}_plan").id)
                @paid_plan = Factory(:plan, cycle: "month", price: 3000)
                # Simulate upgrade
                @site.plan_id = @paid_plan.id
                @invoice = Invoice.build(site: @site)
              end
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

      describe "with a site created" do
        context "before beta discount end" do
          before(:all) do
            @user    = Factory(:user, country: 'FR', created_at: Time.utc(2010,10,10))
            Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.hour) do
              @site = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id)
              @invoice = Invoice.build(site: @site)
            end
          end
          subject { @invoice }

          its(:invoice_items_amount) { should == 800 }
          its(:vat_rate)             { should == 0.0 }
          its(:vat_amount)           { should == 0 }
          its(:amount)               { should == 800 }
        end

        context "after beta discount end" do
          before(:all) do
            @user    = Factory(:user, country: 'FR', created_at: Time.utc(2011,3,30))
            Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.hour) do
              @site = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id)
              @invoice = Invoice.build(site: @site)
            end
          end
          subject { @invoice }

          its(:invoice_items_amount) { should == 1000 }
          its(:vat_rate)             { should == 0.0 }
          its(:vat_amount)           { should == 0 }
          its(:amount)               { should == 1000 }
        end
      end

      describe "with a Swiss user" do
        context "before beta discount end" do
          before(:all) do
            @user    = Factory(:user, country: 'CH', created_at: Time.utc(2010,10,10))
            Timecop.travel(PublicLaunch.beta_transition_ended_on - 1.hour) do
              @site = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id)
              @invoice = Invoice.build(site: @site)
            end
          end
          subject { @invoice }

          its(:invoice_items_amount) { should == 800 }
          its(:vat_rate)             { should == 0.08 }
          its(:vat_amount)           { should == (800 * 0.08).round }
          its(:amount)               { should == 800 + (800 * 0.08).round }
        end

        context "after beta discount end" do
          before(:all) do
            @user    = Factory(:user, country: 'CH')
            Timecop.travel(PublicLaunch.beta_transition_ended_on + 1.hour) do
              @site = Factory.build(:new_site, user: @user, plan_id: @paid_plan.id)
              @invoice = Invoice.build(site: @site)
            end
          end
          subject { @invoice }

          its(:invoice_items_amount) { should == 1000 }
          its(:vat_rate)             { should == 0.08 }
          its(:vat_amount)           { should == (1000 * 0.08).round }
          its(:amount)               { should == 1000 + (1000 * 0.08).round }
        end
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
#  site_hostname         :string(255)
#  amount                :integer
#  vat_rate              :float
#  vat_amount            :integer
#  invoice_items_amount  :integer
#  invoice_items_count   :integer         default(0)
#  transactions_count    :integer         default(0)
#  created_at            :datetime
#  updated_at            :datetime
#  paid_at               :datetime
#  last_failed_at        :datetime
#  renew                 :boolean         default(FALSE)
#
# Indexes
#
#  index_invoices_on_reference  (reference) UNIQUE
#  index_invoices_on_site_id    (site_id)
#

