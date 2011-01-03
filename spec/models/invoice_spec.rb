require 'spec_helper'

describe Invoice do
  before(:all) { @worker = Delayed::Worker.new }
  
  describe "Factory" do
    before(:all) { @invoice = Factory(:invoice) }
    subject { @invoice }
    
    its(:user)                 { should be_present }
    its(:reference)            { should =~ /^[A-Z1-9]{8}$/ }
    its(:invoice_items_amount) { should == 10000 }
    its(:amount)               { should == 10000 }
    its(:started_at)           { should be_present }
    its(:ended_at)             { should be_present }
    its(:paid_at)              { should be_nil }
    its(:attempts)             { should == 0 }
    its(:last_error)           { should be_nil }
    its(:failed_at)            { should be_nil }
    
    it { should be_open }
    it { should be_valid }
  end # Factory
  
  describe "Associations" do
    before(:all) { @invoice = Factory(:invoice) }
    subject { @invoice }
    
    it { should belong_to :user }
    it { should belong_to :charging_delayed_job }
    it { should have_many :invoice_items }
  end # Associations
  
  describe "Scopes" do
    before(:all) do
      @open_invoice    = Factory(:invoice, :state => 'open')
      @paid_invoice    = Factory(:invoice, :state => 'paid')
      @failed_invoice1 = Factory(:invoice, :state => 'failed')
      @failed_invoice2 = Factory(:invoice, :state => 'failed')
    end
    
    describe "#failed" do
      specify { Invoice.failed.all.should == [@failed_invoice1, @failed_invoice2] }
    end
  end
  
  describe "Validations" do
    before(:all) { @invoice = Factory(:invoice) }
    subject { @invoice }
    
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:ended_at) }
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
          
          context "amount == 0" do
            it "should set open invoice directly to paid" do
              subject.reload.amount = 0
              subject.complete
              subject.should be_paid
            end
          end
          
          context "amount != 0" do
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
      end
      
      describe "#retry" do
        context "from failed state" do
          before(:each) { subject.reload.update_attribute(:state, 'failed') }
          
          it "should set open invoice to failed" do
            subject.should be_failed
            subject.retry
            subject.should be_failed
          end
        end
      end
      
      describe "#fail" do
        context "from unpaid state" do
          before(:each) { subject.reload.update_attribute(:state, 'unpaid') }
          
          context "while attempts < Billing.max_charging_attempts" do
            (1...Billing.max_charging_attempts).each do |attempts|
              it "should set invoice to unpaid if it's the attempt ##{attempts}" do
                subject.attempts = attempts
                subject.fail
                subject.should be_unpaid
              end
            end
          end
          
          context "when attempts >= Billing.max_charging_attempts" do
            (Billing.max_charging_attempts..Billing.max_charging_attempts+1).each do |attempts|
              it "should set invoice to failed if it's the attempt ##{attempts}" do
                subject.attempts = attempts
                subject.fail
                subject.should be_failed
              end
            end
          end
        end
        
        context "from failed state" do
          before(:each) { subject.reload.update_attribute(:state, 'failed') }
          
          context "while attempts < Billing.max_charging_attempts" do
            it "should set invoice to failed " do
              subject.should be_failed
              subject.fail
              subject.should be_failed
            end
          end
        end
      end
      
      describe "#succeed" do
        %w[unpaid failed].each do |state|
          context "from #{state} state" do
            before(:each) { subject.reload.update_attribute(:state, state) }
            
            it "should set invoice to paid" do
              subject.succeed
              subject.should be_paid
            end
          end
        end
      end
      
    end # Events
    
    describe "Transitions" do
      
      describe "before_transition :on => :complete, :do => :set_completed_at" do
        before(:each) { subject.reload.update_attribute(:state, 'open') }
        
        it "should set open invoice directly to paid" do
          subject.completed_at.should be_nil
          subject.complete
          subject.completed_at.should be_present
        end
      end
      
      describe "before_transition :on => :retry" do
        context "from failed" do
          before(:each) { subject.reload.update_attributes(:state => 'failed', :attempts => Billing.max_charging_attempts) }
          
          it "should delay Invoice.charge" do
            lambda { subject.retry }.should change(Delayed::Job, :count).by(1)
            Delayed::Job.where(:handler.matches => "%Class%charge%").count.should == 1
          end
          
          it "should not increments attempts" do
            lambda { subject.retry }.should_not change(subject, :attempts)
          end
          
          context "user is suspended" do
            before(:each) { subject.user.reload.update_attribute(:state, 'suspended') }
            
            it "should delay Invoice.charge" do
              lambda { subject.retry }.should change(Delayed::Job, :count).by(1)
              Delayed::Job.where(:handler.matches => "%Class%charge%").count.should == 1
            end
            
            it "should not increments attempts" do
              lambda { subject.retry }.should_not change(subject, :attempts)
            end
            
            it "should not re-delay another charging" do
              lambda { subject.retry }.should change(Delayed::Job, :count).by(1)
              lambda do
                VCR.use_cassette('ogone_visa_payment_2000_alias') { @worker.work_off }
              end.should change(Delayed::Job, :count).by(-1)
            end
          end
        end
      end
      
      describe "before_transition [:open, :unpaid] => [:unpaid, :failed], :do => :delay_charge" do
        context "from open" do
          before(:each) { subject.reload.update_attribute(:state, 'open') }
          
          it "should delay Invoice.charge in Billing.days_before_charging.days" do
            lambda { subject.complete }.should change(Delayed::Job, :count).by(1)
            Delayed::Job.where(:handler.matches => "%Class%charge%").count.should == 1
            Delayed::Job.where(:handler.matches => "%Class%charge%").first.run_at.should be_within(5).of(Billing.days_before_charging.days.from_now) # seconds of tolerance
          end
          
          it "should not increments attempts until charge" do
            lambda { subject.complete }.should_not change(subject, :attempts)
          end
          
          context "user is archived" do
            before(:each) { subject.user.reload.update_attribute(:state, 'archived') }
            
            it "should delay Invoice.charge in 0.seconds" do
              lambda { subject.complete }.should change(Delayed::Job, :count).by(1)
              Delayed::Job.where(:handler.matches => "%Class%charge%").count.should == 1
              Delayed::Job.where(:handler.matches => "%Class%charge%").first.run_at.should be_within(5).of(0.seconds.from_now) # seconds of tolerance
            end
            
            it "should not increments attempts until charge" do
              lambda { subject.complete }.should_not change(subject, :attempts)
            end
          end
          
        end
        
        context "from unpaid" do
          before(:each) { subject.reload.update_attribute(:state, 'unpaid') }
          
          it "should delay Invoice.charge in (2**attempts).hours" do
            lambda { subject.fail }.should change(Delayed::Job, :count).by(1)
            Delayed::Job.where(:handler.matches => "%Class%charge%").count.should == 1
            Delayed::Job.where(:handler.matches => "%Class%charge%").first.run_at.should be_within(5).of((2**1).hours.from_now) # seconds of tolerance
          end
          
          it "should increments attempts" do
            lambda { subject.fail }.should change(subject, :attempts).by(1)
          end
          
          context "user is suspended" do
            before(:each) { subject.user.reload.update_attribute(:state, 'suspended') }
            
            it "should not delay Invoice.charge in 0.seconds" do
              lambda { subject.fail }.should_not change(Delayed::Job, :count)
              Delayed::Job.last.should be_nil
            end
            
            it "should increments attempts" do
              lambda { subject.fail }.should change(subject, :attempts).by(1)
            end
          end
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
      
      describe "before_transition any => :failed, :do => [:set_failed_at, :clear_charging_delayed_job_id]" do
        context "from unpaid" do
          before(:each) { subject.reload.update_attributes(:state => 'unpaid', :attempts => Billing.max_charging_attempts, :charging_delayed_job_id => 1) }
          
          it "should set failed_at" do
            subject.failed_at.should be_nil
            subject.fail
            subject.failed_at.should be_present
          end
          it "should clear charging_delayed_job_id" do
            subject.charging_delayed_job_id.should be_present
            subject.fail
            subject.charging_delayed_job_id.should be_nil
          end
        end
        
        context "from failed" do
          before(:each) { subject.reload.update_attributes(:state => 'failed', :charging_delayed_job_id => 1) }
          
          it "should set failed_at" do
            subject.failed_at.should be_nil
            subject.fail
            subject.failed_at.should be_present
          end
          it "should clear charging_delayed_job_id" do
            subject.charging_delayed_job_id.should be_present
            subject.fail
            subject.charging_delayed_job_id.should be_nil
          end
        end
      end
      
      describe "before_transition :unpaid => :failed, :do => :delay_suspend_user" do
        context "from unpaid" do
          before(:each) { subject.reload.update_attributes(:state => 'unpaid', :attempts => Billing.max_charging_attempts, :charging_delayed_job_id => 1) }
          
          it "should delay suspend user in Billing.days_before_suspend_user days" do
            lambda { subject.fail }.should change(Delayed::Job, :count).by(2)
            Delayed::Job.where(:handler.matches => "%Class%suspend%").count.should == 1
            Delayed::Job.where(:handler.matches => "%Class%suspend%").first.run_at.should be_within(5).of(Billing.days_before_suspend_user.days.from_now) # seconds of tolerance
          end
          
          it "should delay charge user in Billing.days_before_suspend_user days" do
            lambda { subject.fail }.should change(Delayed::Job, :count).by(2)
            Delayed::Job.where(:handler.matches => "%Class%charge%").count.should == 1
            Delayed::Job.where(:handler.matches => "%Class%charge%").first.run_at.should be_within(5).of(Billing.hours_between_retries_before_user_suspend.hours.from_now) # seconds of tolerance
          end
        end
      end
      
      describe "after_transition  :unpaid => :failed, :do => :send_charging_failed_email" do
        context "from unpaid" do
          before(:each) { subject.reload.update_attributes(:state => 'unpaid', :attempts => Billing.max_charging_attempts) }
          
          it "should send an email to invoice.user" do
            lambda { subject.fail }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.user.email]
          end
        end
      end
      
      describe "before_transition [:open, :unpaid, :failed] => :paid, :do => [:set_paid_at, :clear_charging_delayed_job_id]" do
        %w[open unpaid failed].each do |state|
          context "from #{state}" do
            before(:each) { subject.reload.update_attributes(:state => state, :amount => 0, :charging_delayed_job_id => 1) }
            
            it "should set paid_at" do
              subject.paid_at.should be_nil
              subject.send(state == 'open' ? :complete : :succeed)
              subject.paid_at.should be_present
            end
            it "should clear charging_delayed_job_id" do
              subject.charging_delayed_job_id.should be_present
              subject.send(state == 'open' ? :complete : :succeed)
              subject.charging_delayed_job_id.should be_nil
            end
          end
        end
      end
      
      describe "after_transition [:open, :unpaid, :failed] => :paid, :do => :unsuspend_user" do
        context "with a non-suspended user" do
          %w[open unpaid failed].each do |state|
            context "from #{state}" do
              before(:each) do
                subject.reload.update_attributes(:state => state, :amount => 0)
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
                subject.reload.update_attributes(:state => state, :amount => 0)
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
                  Factory(:invoice, :user => subject.user, :state => 'failed', :started_at => Time.now.utc, :ended_at => Time.now.utc)
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
        @plan1  = Factory(:plan, :price => 1000, :overage_price => 100, :player_hits => 2000)
        @addon1 = Factory(:addon, :price => 399)
        @addon2 = Factory(:addon, :price => 499)
        @user   = Factory(:user, :country => 'FR')
        Timecop.travel(Time.utc(2010,2).beginning_of_month) do
          @site = Factory(:site, :user => @user, :plan => @plan1, :addon_ids => [@addon1.id, @addon2.id], :activated_at => Time.now)
        end
      end
      before(:each) do
        player_hits = { :main_player_hits => 1500 }
        Factory(:site_usage, player_hits.merge(:site_id => @site.id, :day => Time.utc(2010,1,15).beginning_of_day))
        Factory(:site_usage, player_hits.merge(:site_id => @site.id, :day => Time.utc(2010,2,1).beginning_of_day))
        Factory(:site_usage, player_hits.merge(:site_id => @site.id, :day => Time.utc(2010,2,20).beginning_of_day))
        Factory(:site_usage, player_hits.merge(:site_id => @site.id, :day => Time.utc(2010,3,1).beginning_of_day))
      end
      subject { Invoice.build(:user => @user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month) }
      
      context "with a Swiss user" do
        before(:each) { @user.reload.update_attribute(:country, 'CH') }
        
        its(:invoice_items_amount) { should == 1000 + 399 + 499 + 100 }
        its(:vat_rate)             { should == 0.08 }
        its(:vat_amount)           { should == ((1000 + 399 + 499 + 100) * 0.08).round }
        its(:amount)               { should == 1000 + 399 + 499 + 100 + ((1000 + 399 + 499 + 100) * 0.08).round }
      end
      
      describe "minimum billable amount" do
        before(:all) do
          @cheap_user = Factory(:user, :country => 'FR')
          @cheap_plan = Factory(:plan, :price => 200)
          Timecop.travel(Time.utc(2010,2).beginning_of_month) do
            @cheap_site = Factory(:site, :user => @cheap_user, :plan => @cheap_plan, :activated_at => Time.now)
          end
        end
        subject { Invoice.build(:user => @cheap_user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month) }
        
        its(:invoice_items_amount) { should == Billing.minimum_billable_amount }
        its(:vat_rate)             { should == 0 }
        its(:vat_amount)           { should == 0 }
        its(:amount)               { should == Billing.minimum_billable_amount }
      end
      
      context "site plan has not changed between invoice.ended_at and Time.now" do
        before(:each) { @user.reload }
        
        specify { subject.invoice_items.size.should == 1 + 2 + 1 } # 1 plan, 2 addon lifetimes, 1 overage
        specify do
          invoice_items_items = subject.invoice_items.map(&:item)
          invoice_items_items.should include(@plan1)
          invoice_items_items.should include(@plan1)
          invoice_items_items.should include(@addon1)
          invoice_items_items.should include(@addon2)
        end
        specify { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
        specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
        
        its(:invoice_items_amount) { should == 1000 + 399 + 499 + 100 } # plan.price + addon1.price + addon2.price + 1 overage block
        its(:vat_rate)             { should == 0.0 }
        its(:vat_amount)           { should == 0 }
        its(:amount)               { should == 1000 + 399 + 499 + 100 } # plan.price + addon1.price + addon2.price + 1 overage block
        its(:started_at)           { should == Time.utc(2010,2).beginning_of_month }
        its(:ended_at)             { should == Time.utc(2010,2).end_of_month }
        its(:paid_at)              { should be_nil }
        its(:attempts)             { should == 0 }
        its(:last_error)           { should be_nil }
        its(:failed_at)            { should be_nil }
        it { should be_open }
      end
      
      context "site plan has changed between invoice.ended_at and Time.now (site used in the invoice should be the one at the moment at the end of the period given to build)" do
        before(:all) do
          @plan2  = Factory(:plan, :price => 999999, :overage_price => 999, :player_hits => 200)
          @addon3 = Factory(:addon, :price => 9999)
          Timecop.travel(Time.utc(2010,3,2)) do
            with_versioning { @site.reload.update_attributes(:plan_id => @plan2.id, :addon_ids => [@addon3.id]) }
          end
        end
        
        specify { subject.invoice_items.size.should == 1 + 2 + 1 } # 1 plan, 2 addon lifetimes, 1 overage
        specify do
          invoice_items_items = subject.invoice_items.map(&:item)
          invoice_items_items.should include(@plan1)
          invoice_items_items.should include(@plan1)
          invoice_items_items.should include(@addon1)
          invoice_items_items.should include(@addon2)
        end
        specify { subject.invoice_items.all? { |ii| ii.site == @site.version_at(Time.utc(2010,2).end_of_month) }.should be_true }
        specify { subject.invoice_items.all? { |ii| ii.invoice == subject }.should be_true }
        
        its(:invoice_items_amount) { should == 1000 + 399 + 499 + 100 } # plan.price + addon1.price + addon2.price + 1 overage block
        its(:amount)               { should == 1000 + 399 + 499 + 100 } # plan.price + addon1.price + addon2.price + 1 overage block
        its(:started_at)           { should == Time.utc(2010,2).beginning_of_month }
        its(:ended_at)             { should == Time.utc(2010,2).end_of_month }
        its(:paid_at)              { should be_nil }
        its(:attempts)             { should == 0 }
        its(:last_error)           { should be_nil }
        its(:failed_at)            { should be_nil }
        it { should be_open }
      end
    end # .build
    
    describe ".complete_invoices_for_billable_users" do
      before(:all) do
        Invoice.delete_all
        User.delete_all
        @user1 = Factory(:user)
        @user2 = Factory(:user)
        @user3 = Factory(:user)
        @user4 = Factory(:user)
        @site1 = Factory(:site, :user => @user1, :activated_at => Time.utc(2010,2).beginning_of_month)
        @site2 = Factory(:site, :user => @user2, :activated_at => Time.utc(2010,2,15))
        @site3 = Factory(:site, :user => @user3, :activated_at => Time.utc(2010,2,28,23,58))
        @site4 = Factory(:site, :user => @user4, :activated_at => Time.utc(2010,3,15))
        player_hits = { :main_player_hits => 1500 }
        Factory(:site_usage, player_hits.merge(:site_id => @site1.id, :day => Time.utc(2010,2,15).beginning_of_day))
        Factory(:site_usage, player_hits.merge(:site_id => @site2.id, :day => Time.utc(2010,2,20).beginning_of_day))
        Factory(:site_usage, player_hits.merge(:site_id => @site2.id, :day => Time.utc(2010,2,21).beginning_of_day))
      end
      subject { Invoice.complete_invoices_for_billable_users(Time.utc(2010,2).beginning_of_month, Time.utc(2010,2).end_of_month) }
      
      specify { lambda { subject }.should change(Invoice, :count).by(3) }
      specify { lambda { subject }.should change(@user1.invoices, :count).by(1) }
      specify { lambda { subject }.should change(@user2.invoices, :count).by(1) }
      specify { lambda { subject }.should change(@user3.invoices, :count).by(1) }
      
      describe "delay complete_invoices_for_billable_users" do
        before(:each) { Timecop.travel(Time.utc(2009,1)) }
        after(:each) { Timecop.return }
        subject { Invoice.complete_invoices_for_billable_users(Time.utc(2009,1).beginning_of_month, Time.utc(2009,1).end_of_month) }
        
        it "should delay complete_invoices_for_billable_users" do
          lambda { subject }.should change(Delayed::Job, :count).by(1)
          handler = YAML.load(Delayed::Job.last.handler)
          handler['args'][0].to_i.should == Time.utc(2009,2).beginning_of_month.to_i
          handler['args'][1].to_i.should == Time.utc(2009,2).end_of_month.to_i
        end
        
        it "should delay complete_invoices_for_billable_users Billing.days_before_creating_invoice days after ended_at of the next invoice" do
          subject
          Delayed::Job.last.run_at.should == Time.utc(2009,2).end_of_month + Billing.days_before_creating_invoice.days
        end
        
        it "should not delay complete_invoices_for_billable_users if one pending already present" do
          subject
          lambda { Invoice.complete_invoices_for_billable_users(Time.utc(2009,2).beginning_of_month, Time.utc(2009,2).end_of_month) }.should_not change(Delayed::Job, :count)
        end
      end
      
      describe "delay_charge" do
        it "should only delay charge for invoices with amount > 0" do
          lambda { subject }.should change(Delayed::Job.where(:handler.matches => "%charge%"), :count).by(2)
        end
        
        it "should delay charge in Billing.days_before_charging days from now" do
          subject
          Delayed::Job.find(@user1.invoices[0].charging_delayed_job_id).run_at.should be_within(5).of(Billing.days_before_charging.days.from_now) # seconds of tolerance
          Delayed::Job.find(@user2.invoices[0].charging_delayed_job_id).run_at.should be_within(5).of(Billing.days_before_charging.days.from_now) # seconds of tolerance
        end
      end
      
      describe "charging_delayed_job_id" do
        it "should set charging_delayed_job_id for invoices that have amount > 0" do
          subject
          @user1.invoices[0].charging_delayed_job_id.should be_present
          @user2.invoices[0].charging_delayed_job_id.should be_present
        end
        it "should not set charging_delayed_job_id for invoices that have amount == 0" do
          subject
          @user3.invoices[0].charging_delayed_job_id.should_not be_present
        end
      end
      
      describe "state" do
        it "should set invoices with amount > 0 as 'unpaid'" do
          subject
          @user1.invoices[0].should be_unpaid
          @user2.invoices[0].should be_unpaid
        end
        
        it "should set invoices with amount == 0 as 'paid'" do
          subject
          @user3.invoices[0].should be_paid
        end
      end
      
      describe "send mail" do
        before(:each) { ActionMailer::Base.deliveries.clear }
        
        specify { lambda { subject }.should change(ActionMailer::Base.deliveries, :count).by(2) }
        specify do
          subject
          ActionMailer::Base.deliveries.map(&:to).should == [[@user1.email], [@user2.email]]
        end
      end
      
      it "should set completed_at" do
        subject
        Invoice.all.all? { |invoice| invoice.completed_at.present? }.should be_true
      end
    end # .complete_invoices_for_billable_users
    
    describe ".charge" do
      before(:all) do
        @user    = Factory(:user)
        @invoice = Factory(:invoice, :user => @user, :amount => 2000, :state => 'unpaid')
      end
      subject { Invoice.charge(@invoice.id) }
      
      describe "common logic" do
        use_vcr_cassette "ogone_visa_payment_2000_alias"
        before(:each) do
          @invoice.reload.update_attributes(:reference => "1234")
        end
        
        it "should pass right options" do
          Ogone.should_receive(:purchase).with(@invoice.amount, @user.credit_card_alias, :order_id => @invoice.reference, :currency => 'USD')
          subject
        end
      end
      
      context "with a succeeding purchase" do
        use_vcr_cassette "ogone_visa_payment_2000_alias"
        before(:each) do
          @invoice.reload.update_attribute(:charging_delayed_job_id, 1)
        end
        
        it "should not set last_error" do
          @invoice.last_error.should be_nil
          subject
          @invoice.reload.last_error.should be_nil
        end
        
        it "should receive succeed" do
          Invoice.stub!(:find) { @invoice }
          @invoice.should_receive(:succeed)
          subject
        end
        
        describe "succeed event callbacks checks" do
          it "should set state to 'paid'" do
            @invoice.should be_unpaid
            subject
            @invoice.reload.should be_paid
          end
          it "should clear charging_delayed_job_id" do
            @invoice.charging_delayed_job_id.should == 1
            subject
            @invoice.reload.charging_delayed_job_id.should be_nil
          end
          it "should set paid_at to Time.now.utc" do
            @invoice.paid_at.should be_nil
            subject
            @invoice.reload.paid_at.should be_present
          end
          it "should increments attempts" do
            lambda { subject; @invoice.reload }.should change(@invoice, :attempts).by(1)
          end
        end
      end
      
      context "with a failing purchase" do
        use_vcr_cassette "ogone_visa_payment_9999"
        
        (0...Billing.max_charging_attempts).each do |attempts|
          context "with only #{attempts} attempt(s) failed" do
            before(:each) do
              @invoice.reload.update_attributes(:attempts => attempts, :charging_delayed_job_id => 1)
            end
            
            it "should set last_error" do
              @invoice.last_error.should be_nil
              subject
              @invoice.reload.last_error.should be_present
            end
            
            it "should receive fail" do
              Invoice.stub!(:find) { @invoice }
              @invoice.should_receive(:fail)
              subject
            end
            
            describe "fail event callbacks checks" do
              it "should set state to 'unpaid'" do
                @invoice.should be_unpaid
                subject
                @invoice.reload.should be_unpaid
              end
              it "should not set paid_at" do
                @invoice.paid_at.should be_nil
                subject
                @invoice.reload.paid_at.should be_nil
              end
              describe "delay charging" do
                it "should delay suspend user" do
                  lambda { subject }.should change(Delayed::Job, :count).by(1)
                  Delayed::Job.where(:handler.matches => "%Class%charge%").count.should == 1
                end
                it "should delay charging in 2**#{attempts} hours " do
                  subject
                  Delayed::Job.last.run_at.should be_within(5).of((2**@invoice.reload.attempts).hours.from_now) # seconds of tolerance
                end
                it "should set charging_delayed_job_id to the new delayed job created" do
                  @invoice.charging_delayed_job_id.should == 1
                  subject
                  @invoice.reload.charging_delayed_job_id.should == Delayed::Job.last.id
                end
              end
              it "should increments attempts" do
                lambda { subject; @invoice.reload }.should change(@invoice, :attempts).by(1)
              end
            end
          end
        end
        
        context "with #{Billing.max_charging_attempts} attempts failed" do
          before(:each) do
            @invoice.reload.update_attributes(:attempts => Billing.max_charging_attempts, :charging_delayed_job_id => 1)
          end
          
          it "should set last_error" do
            @invoice.last_error.should be_nil
            subject
            @invoice.reload.last_error.should be_present
          end
          
          it "should receive fail" do
            Invoice.stub!(:find) { @invoice }
            @invoice.should_receive(:fail)
            subject
          end
          
          describe "fail event callbacks checks" do
            it "should set state to 'failed'" do
              @invoice.should be_unpaid
              subject
              @invoice.reload.should be_failed
            end
            it "should not set paid_at" do
              @invoice.paid_at.should_not be_present
              subject
              @invoice.reload.paid_at.should_not be_present
            end
            it "should clear charging_delayed_job_id" do
              @invoice.charging_delayed_job_id.should == 1
              subject
              @invoice.reload.charging_delayed_job_id.should be_nil
            end
            it "should increments attempts" do
              lambda { subject; @invoice.reload }.should change(@invoice, :attempts).by(1)
            end
            describe "delay user.suspend" do
              it "should delay user.suspend in Billing.days_before_suspend_user days" do
                lambda { subject }.should change(Delayed::Job, :count).by(2)
                Delayed::Job.where(:handler.matches => "%Class%suspend%").count.should == 1
                Delayed::Job.where(:handler.matches => "%Class%suspend%").last.run_at.should be_within(5).of(Billing.days_before_suspend_user.days.from_now) # seconds of tolerance
              end
              it "should delay Invoice.charge in Billing.hours_between_retries_before_user_suspend hours" do
                lambda { subject }.should change(Delayed::Job, :count).by(2)
                Delayed::Job.where(:handler.matches => "%Class%charge%").count.should == 1
                Delayed::Job.where(:handler.matches => "%Class%charge%").last.run_at.should be_within(5).of(Billing.hours_between_retries_before_user_suspend.hours.from_now) # seconds of tolerance
              end
            end
            describe "send mail" do
              before(:each) { ActionMailer::Base.deliveries.clear }
              
              specify { lambda { subject }.should change(ActionMailer::Base.deliveries, :count).by(1) }
              specify do
                subject
                ActionMailer::Base.deliveries.last.to.should == [@user.email]
              end
            end
          end
        end
        
        context "with an exception raised by Ogone.purchase" do
          before(:each) do
            Ogone.should_receive(:purchase).and_raise("Exception")
            Notify.stub!(:send)
            @invoice.reload
          end
          
          specify { expect { subject }.to_not raise_error }
          it "should Notify of the exception" do
            Notify.should_receive(:send)
            subject
          end
          it "should fail the invoice" do
            Invoice.stub!(:find) { @invoice }
            @invoice.should_receive(:fail)
            subject
          end
          it "should increments attempts" do
            lambda { subject; @invoice.reload }.should change(@invoice, :attempts).by(1)
          end
        end
      end
      
      context "with a already charged invoice" do
        context "with paid state" do
          before(:each) do
            @invoice.reload.update_attribute(:state, 'paid')
          end
          
          specify { Ogone.should_not_receive(:purchase) }
          specify do
            @invoice.should_not_receive(:succeed)
            @invoice.should_not_receive(:fail)
            subject
          end
          it "should not increments attempts" do
            lambda { subject; @invoice.reload }.should_not change(@invoice, :attempts)
          end
        end
        
        context "but invalid state (not paid)" do
          use_vcr_cassette "ogone_visa_payment_2000_already_processed"
          before(:each) do
            @invoice.reload.update_attribute(:charging_delayed_job_id, 1)
          end
          
          it "should set paid_at to Time.now.utc" do
            @invoice.paid_at.should be_nil
            subject
            @invoice.reload.paid_at.should be_present
          end
          it "should clear charging_delayed_job_id" do
            @invoice.charging_delayed_job_id.should == 1
            subject
            @invoice.reload.charging_delayed_job_id.should be_nil
          end
          it "should set state to 'paid'" do
            @invoice.should be_unpaid
            subject
            @invoice.reload.should be_paid
          end
          it "should increments attempts" do
            lambda { subject; @invoice.reload }.should change(@invoice, :attempts).by(1)
          end
        end
      end
      
    end # .charge
    
  end # Class Methods
  
  describe "#minutes_in_months" do
    context "with invoice included in one month" do
      subject { Factory(:invoice, :started_at => Time.utc(2010,2,10), :ended_at => Time.utc(2010,2,27)) }
      
      it "should return minutes in the month where started_at and ended_at are included" do
        subject.minutes_in_months.should == 28 * 24 * 60
      end
    end
    context "with invoice included in two month" do
      subject { Factory(:invoice, :started_at => Time.utc(2010,2,10), :ended_at => Time.utc(2010,3,27)) }
      
      it "should return minutes in the month where started_at and ended_at are included" do
        subject.minutes_in_months.should == (28+31) * 24 * 60
      end
    end
  end # #minutes_in_months
  
end




# == Schema Information
#
# Table name: invoices
#
#  id                      :integer         not null, primary key
#  user_id                 :integer
#  reference               :string(255)
#  state                   :string(255)
#  amount                  :integer
#  started_at              :datetime
#  ended_at                :datetime
#  paid_at                 :datetime
#  attempts                :integer         default(0)
#  last_error              :string(255)
#  failed_at               :datetime
#  created_at              :datetime
#  updated_at              :datetime
#  completed_at            :datetime
#  charging_delayed_job_id :integer
#  invoice_items_amount    :integer
#  vat_rate                :float
#  vat_amount              :integer
#
# Indexes
#
#  index_invoices_on_user_id                 (user_id)
#  index_invoices_on_user_id_and_ended_at    (user_id,ended_at) UNIQUE
#  index_invoices_on_user_id_and_started_at  (user_id,started_at) UNIQUE
#

