require 'spec_helper'

describe Invoice do
  
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
  
  describe "Validations" do
    before(:all) { @invoice = Factory(:invoice) }
    subject { @invoice }
    
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:started_at) }
    it { should validate_presence_of(:ended_at) }
    it { should validate_presence_of(:invoice_items_amount) }
    it { should validate_presence_of(:amount) }
    
    it { should validate_numericality_of(:invoice_items_amount) }
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
      
      describe "#fail" do
        context "from unpaid state" do
          before(:each) { subject.reload.update_attribute(:state, 'unpaid') }
          
          context "while attempts < Billing.max_charging_attempts" do
            (1...Billing.max_charging_attempts).each do |attempts|
              it "should set unpaid invoice to unpaid if it's the attempt ##{attempts}" do
                subject.attempts = attempts
                subject.fail
                subject.should be_unpaid
              end
            end
          end
          
          context "when attempts >= Billing.max_charging_attempts" do
            (Billing.max_charging_attempts..Billing.max_charging_attempts+1).each do |attempts|
              it "should set unpaid invoice to failed if it's the attempt ##{attempts}" do
                subject.attempts = attempts
                subject.fail
                subject.should be_failed
              end
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
      
      describe "before_transition [:open, :unpaid] => :unpaid, :do => [:delay_charge_and_set_charging_delayed_job_id, :increment_attempts]" do
        context "from open" do
          before(:each) { subject.reload.update_attribute(:state, 'open') }
          
          it "should delay Invoice.charge" do
            lambda { subject.complete }.should change(Delayed::Job, :count).by(1)
            Delayed::Job.last.name.should == "Class#charge"
          end
          
          it "should increments attempts" do
            lambda { subject.complete }.should change(subject, :attempts).by(1)
          end
        end
        
        context "from unpaid" do
          before(:each) { subject.reload.update_attribute(:state, 'unpaid') }
          
          it "should delay Invoice.charge" do
            lambda { subject.fail }.should change(Delayed::Job, :count).by(1)
            Delayed::Job.last.name.should == "Class#charge"
          end
          
          it "should increments attempts" do
            lambda { subject.fail }.should change(subject, :attempts).by(1)
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
        end
      end
      
      describe "before_transition :unpaid => :failed, :do => [:clear_charging_delayed_job_id, :delay_suspend_user]" do
        context "from unpaid" do
          before(:each) { subject.reload.update_attributes(:state => 'unpaid', :attempts => Billing.max_charging_attempts, :charging_delayed_job_id => 1) }
          
          it "should clear charging_delayed_job_id" do
            subject.charging_delayed_job_id.should be_present
            subject.fail
            subject.charging_delayed_job_id.should be_nil
          end
          
          it "should delay suspend user" do
            lambda { subject.fail }.should change(Delayed::Job, :count).by(1)
            Delayed::Job.last.name.should == "Class#suspend"
          end
          
          it "should delay User.suspend in Billing.days_before_suspend_user days" do
            subject.fail
            Delayed::Job.last.run_at.should be_within(3).of(Billing.days_before_suspend_user.days.from_now) # seconds of tolerance
          end
        end
      end
      
      describe "after_transition  :unpaid => :failed, :do => :send_payment_failed_email" do
        context "from unpaid" do
          before(:each) { subject.reload.update_attributes(:state => 'unpaid', :attempts => Billing.max_charging_attempts) }
          
          it "should send an email to invoice.user" do
            lambda { subject.fail }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [subject.user.email]
          end
        end
      end
      
      describe "before_transition [:open, :unpaid, :failed] => :paid, :do => [:clear_charging_delayed_job_id, :set_paid_at]" do
        context "from open" do
          before(:each) { subject.reload.update_attributes(:state => 'open', :amount => 0, :charging_delayed_job_id => 1) }
          
          it "should clear charging_delayed_job_id" do
            subject.charging_delayed_job_id.should be_present
            subject.complete
            subject.charging_delayed_job_id.should be_nil
          end
          
          it "should set paid_at" do
            subject.paid_at.should be_nil
            subject.complete
            subject.paid_at.should be_present
          end
        end
        
        %w[unpaid failed].each do |state|
          context "from #{state}" do
            before(:each) { subject.reload.update_attributes(:state => state, :charging_delayed_job_id => 1) }
            
            it "should clear charging_delayed_job_id" do
              subject.charging_delayed_job_id.should be_present
              subject.succeed
              subject.charging_delayed_job_id.should be_nil
            end
            
            it "should set paid_at" do
              subject.paid_at.should be_nil
              subject.succeed
              subject.paid_at.should be_present
            end
          end
        end
      end
      
    end # Transitions
    
  end
  
  describe "Class Methods" do
    
    describe ".build" do
      before(:all) do
        @plan1  = Factory(:plan, :price => 1000, :overage_price => 100, :player_hits => 2000)
        @addon1 = Factory(:addon, :price => 399)
        @addon2 = Factory(:addon, :price => 499)
        @user   = Factory(:user)
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
      
      context "site plan has not changed between invoice.ended_at and Time.now" do
        subject { Invoice.build(:user => @user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month) }
        
        specify { subject.invoice_items.size.should == 1 + 2 + 1 } # 1 plan, 2 addon lifetimes, 1 overage
        specify { subject.invoice_items[0].item.should == @plan1 }
        specify { subject.invoice_items[1].item.should == @plan1 }
        specify { subject.invoice_items[2].item.should == @addon1 }
        specify { subject.invoice_items[3].item.should == @addon2 }
        
        specify { subject.invoice_items.all? { |ii| ii.site == @site }.should be_true }
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
      
      context "site plan has changed between invoice.ended_at and Time.now" do
        before(:all) do
          @plan2  = Factory(:plan, :price => 999999, :overage_price => 999, :player_hits => 200)
          @addon3 = Factory(:addon, :price => 9999)
          Timecop.travel(Time.utc(2010,3,2)) do
            with_versioning { @site.reload.update_attributes(:plan_id => @plan2.id, :addon_ids => [@addon3.id]) }
          end
        end
        subject { Invoice.build(:user => @user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month) }
        
        specify { subject.invoice_items.size.should == 1 + 2 + 1 } # 1 plan, 2 addon lifetimes, 1 overage
        specify { subject.invoice_items[0].item.should == @plan1 }
        specify { subject.invoice_items[1].item.should == @plan1 }
        specify { subject.invoice_items[2].item.should == @addon1 }
        specify { subject.invoice_items[3].item.should == @addon2 }
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
    end
    
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
      
      describe "delay_charge" do
        it "should only delay charge for invoices with amount > 0" do
          lambda { subject }.should change(Delayed::Job.where(:handler.matches => "%charge%"), :count).by(2)
        end
        
        it "should delay charge in Billing.days_before_charging days from now" do
          subject
          Delayed::Job.find(@user1.invoices[0].charging_delayed_job_id).run_at.should be_within(3).of(Billing.days_before_charging.days.from_now) # seconds of tolerance
          Delayed::Job.find(@user2.invoices[0].charging_delayed_job_id).run_at.should be_within(3).of(Billing.days_before_charging.days.from_now) # seconds of tolerance
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
    end
    
    describe ".charge" do
      before(:all) do
        @user    = Factory(:user)
        @invoice = Factory(:invoice, :user => @user, :amount => 2000, :state => 'unpaid')
      end
      subject { Invoice.charge(@invoice.id) }
      
      describe "Ogone call" do
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
        end
      end
      
      context "with a failing purchase" do
        use_vcr_cassette "ogone_visa_payment_9999"
        
        (1...Billing.max_charging_attempts).each do |attempts|
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
                specify { lambda { subject }.should change(Delayed::Job.where(:handler.matches => "%charge%"), :count).by(1) }
                it "should delay charging in 2**#{attempts} hours " do
                  subject
                  Delayed::Job.last.run_at.should be_within(3).of((2**attempts).hours.from_now) # seconds of tolerance
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
            describe "delay User.suspend" do
              specify { lambda { subject }.should change(Delayed::Job.where(:handler.matches => "%suspend%"), :count).by(1) }
              it "should delay User.suspend in Billing.days_before_suspend_user days" do
                subject
                Delayed::Job.last.run_at.should be_within(3).of(Billing.days_before_suspend_user.days.from_now) # seconds of tolerance
              end
            end
            describe "send mail" do
              before(:each) { ActionMailer::Base.deliveries.clear }
              
              specify { lambda { subject }.should change(ActionMailer::Base.deliveries, :count).by(1) }
              specify do
                subject
                ActionMailer::Base.deliveries.map(&:to).should == [[@user.email]]
              end
            end
          end
        end
        
        pending "with an exception raised by Ogone.purchase" do
          before(:each) do
            Ogone.stub!(:purchase).and_raise(Exception)
          end
          
          it "should Notify of the exception" do
            Notify.should_receive(:send)
            expect { subject }.to raise_error(Exception)
          end
          
          it "should fail the invoice" do
            @invoice.should_receive(:fail)
            expect { subject }.to raise_error(Exception)
          end
        end
      end
      
      context "with a already charged invoice" do
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
      end
      
    end
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
  end
  
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
#
# Indexes
#
#  index_invoices_on_user_id                 (user_id)
#  index_invoices_on_user_id_and_ended_at    (user_id,ended_at) UNIQUE
#  index_invoices_on_user_id_and_started_at  (user_id,started_at) UNIQUE
#

