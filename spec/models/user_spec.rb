require 'spec_helper'

# before refactoring: 18.52s
# after refactoring:  11.06s
# 1.67x faster
describe User do
  before(:all) { @worker = Delayed::Worker.new }
  
  context "Factory" do
    before(:all) { @user = Factory(:user) }
    subject { @user }
    
    its(:terms_and_conditions) { should be_true }
    its(:first_name)           { should == "John" }
    its(:last_name)            { should == "Doe" }
    its(:full_name)            { should == "John Doe" }
    its(:country)              { should == "CH" }
    its(:postal_code)          { should == "2000" }
    its(:use_personal)         { should be_true }
    its(:email)                { should match /email\d+@user.com/ }
    
    it { should be_valid }
  end
  
  describe "Associations" do
    before(:all) { @user = Factory(:user) }
    subject { @user }
    
    it { should belong_to :suspending_delayed_job }
    it { should have_many :sites }
    it { should have_many :invoices }
  end
  
  describe "Scopes" do
    
    describe "#billable" do
      before(:all) do
        @user1 = Factory(:user)
        Factory(:site, :user => @user1, :activated_at => Time.utc(2010,1,15))
        Factory(:site, :user => @user1, :activated_at => Time.utc(2010,2,15))
        @user2 = Factory(:user)
        Factory(:site, :user => @user2, :activated_at => Time.utc(2010,2,1), :archived_at => Time.utc(2010,2,2))
        @user3 = Factory(:user)
        Factory(:site, :user => @user3, :activated_at => Time.utc(2010,2,1), :archived_at => Time.utc(2010,2,20))
        @user4 = Factory(:user)
        Factory(:site, :user => @user4, :activated_at => Time.utc(2010,2,1), :archived_at => Time.utc(2010,2,28))
        @user5 = Factory(:user, :state => 'archived')
        Factory(:site, :user => @user5, :activated_at => Time.utc(2010,2,1), :archived_at => Time.utc(2010,2,28))
      end
      
      specify { User.billable(Time.utc(2010,1,1), Time.utc(2010,1,10)).should == [] }
      specify { User.billable(Time.utc(2010,1,1), Time.utc(2010,1,25)).should == [@user1] }
      specify { User.billable(Time.utc(2010,2,5), Time.utc(2010,2,25)).should == [@user1, @user3, @user4] }
      specify { User.billable(Time.utc(2010,2,21), Time.utc(2010,2,25)).should == [@user1, @user4] }
    end
    
  end
  
  describe "Validations" do
    [:first_name, :last_name, :email, :remember_me, :password, :postal_code, :country, :use_personal, :use_company, :use_clients, :company_name, :company_url, :company_job_title, :company_employees, :company_videos_served, :terms_and_conditions, :cc_update, :cc_type, :cc_full_name, :cc_number, :cc_expire_on, :cc_verification_value].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    # Devise checks presence/uniqueness/format of email, presence/length of password
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:postal_code) }
    it { should validate_presence_of(:country) }
    it { should validate_acceptance_of(:terms_and_conditions) }
    
    it "should validate presence of at least one usage" do
      user = Factory.build(:user, :use_personal => nil, :use_company => nil, :use_clients => nil)
      user.should_not be_valid
      user.should have(1).error_on(:use)
      user.errors[:use].should == ["Please check at least one option"]
    end
    
    context "when use_company is checked" do
      it "should validate company fields if use_company is checked" do
        fields = [:company_name, :company_url, :company_job_title, :company_employees, :company_videos_served]
        user = Factory.build(:user, Hash[fields.map { |f| [f, nil] }].merge({ :use_personal => false, :use_company => true }))
        user.should_not be_valid
        fields.each do |f|
          user.should have(1).error_on(f)
        end
      end
      
      it "should validate company url" do
        user = Factory.build(:user, :use_company => true, :company_url => "http://localhost")
        user.should_not be_valid
        user.should have(1).error_on(:company_url)
      end
    end
  end
  
  describe "user credit card when at least 1 credit card field is given" do
    it "should be valid without any credit card field" do
      user = Factory.build(:user, :cc_update => nil, :cc_number => nil, :cc_first_name => nil, :cc_last_name => nil, :cc_verification_value => nil, :cc_expire_on => nil)
      user.should be_valid
    end
    
    context "with at least a credit card field given" do
      it "should require first and last name" do
        user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_first_name => "Bob")
        user.should_not be_valid
        user.should have(1).error_on(:cc_full_name)
      end
      
      it "should not allow expire date in the future" do
        user = Factory.build(:user, :cc_full_name => "John Doe", :cc_expire_on => 1.year.ago)
        user.should_not be_valid
        user.should have(2).errors_on(:cc_expire_on)
      end
      
      describe "credit card number" do
        it "should require one" do
          user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe")
          user.should_not be_valid
          user.should have(1).error_on(:cc_number)
        end
        
        it "should require a valid one" do
          user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe", :cc_number => '1234')
          user.should_not be_valid
          user.should have(1).error_on(:cc_number)
        end
      end
      
      describe "credit card type" do
        it "should require one" do
          user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe")
          user.should_not be_valid
          user.should have(2).errors_on(:cc_type)
        end
        
        it "should require a valid one" do
          user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe", :cc_type => 'foo')
          user.should_not be_valid
          user.should have(1).error_on(:cc_type)
        end
      end
      
      it "should require a credit card verification value" do
        user = Factory.build(:user, :cc_expire_on => 1.year.from_now, :cc_full_name => "John Doe")
        user.should_not be_valid
        user.should have(1).error_on(:cc_verification_value)
      end
    end
  end
  
  context "invited" do
    subject { Factory(:user).tap { |u| u.send(:attributes=, { :invitation_token => '123', :invitation_sent_at => Time.now, :email => "bob@bob.com", :enthusiast_id => 12 }, false); u.save(:validate => false) } }
    
    it "should set enthusiast_id" do
      subject.should be_invited
      subject.enthusiast_id.should == 12
    end
    
    it "should not be able to update enthusiast_id" do
      subject.update_attributes(:enthusiast_id => 13)
      subject.enthusiast_id.should == 12
    end
  end
  
  # TODO slow: 8.8s for 5 examples => 1.76s/ex
  describe "State Machine" do
    let(:user) { Factory(:user) }
    
    describe "Initial State" do
      subject { user }
      it { should be_active }
    end
    
    describe "#suspend" do
      let(:site1) { Factory(:site, :user => user, :hostname => "rymai.com").tap { |s| s.update_attribute(:state, 'active') } }
      let(:site2) { Factory(:site, :user => user, :hostname => "octavez.com").tap { |s| s.update_attribute(:state, 'dev') } }
      
      context "from active state" do
        it "should set user to suspended" do
          user.should be_active
          user.suspend
          user.should be_suspended
        end
      end
      
      describe "Callbacks" do
        describe "before_transition :on => :suspend, :do => :suspend_sites" do
          it "should suspend each user' active site" do
            site1.should be_active
            site2.should be_dev
            user.suspend
            site1.reload.should be_suspended
            site2.reload.should be_dev
          end
        end
        
        describe "after_transition  :on => :suspend, :do => :send_account_suspended_email" do
          it "should send an email to invoice.user" do
            user
            lambda { user.suspend }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [user.email]
          end
        end
      end
    end
    
    describe "#cancel_suspend" do
      before(:each) do
        user.delay_suspend_and_set_suspending_delayed_job_id
      end
      subject { user }
      
      context "from active state" do
        it "should set user to active" do
          subject.should be_active
          subject.cancel_suspend
          subject.should be_active
        end
      end
      
      describe "Callbacks" do
        describe "before_transition :on => :cancel_suspend, :do => :clear_suspending_delayed_job_id" do
          it "should clear suspending_delayed_job_id" do
            subject.suspending_delayed_job_id.should be_present
            subject.cancel_suspend
            subject.suspending_delayed_job_id.should be_nil
          end
          
          it "should clear the delayed job scheduled to suspend the user" do
            delayed_job_id = subject.suspending_delayed_job_id
            Delayed::Job.find(delayed_job_id).should be_present
            subject.cancel_suspend
            lambda { Delayed::Job.find(delayed_job_id) }.should raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
    
    describe "#unsuspend" do
      let(:site1) { Factory(:site, :user => user, :hostname => "rymai.com").tap { |s| s.update_attribute(:state, 'suspended') } }
      let(:site2) { Factory(:site, :user => user, :hostname => "octavez.com").tap { |s| s.update_attribute(:state, 'dev') } }
      before(:each) { user.update_attribute(:state, 'suspended') }
      
      context "from suspended state" do
        it "should set the user to active" do
          user.should be_suspended
          user.unsuspend
          user.should be_active
        end
      end
      
      describe "Callbacks" do
        describe "before_transition :on => :unsuspend, :do => :unsuspend_sites" do
          it "should suspend each user' site" do
            site1.reload.should be_suspended
            site2.reload.should be_dev
            user.unsuspend
            site1.reload.should be_active
            site2.reload.should be_dev
          end
        end
        
        describe "after_transition  :on => :unsuspend, :do => :send_account_unsuspended_email" do
          it "should send an email to invoice.user" do
            lambda { user.unsuspend }.should change(ActionMailer::Base.deliveries, :count).by(1)
            ActionMailer::Base.deliveries.last.to.should == [user.email]
          end
        end
      end
    end
    
  end
  
  # TODO slow: 3s for 4 examples => 0.75s/ex
  describe "Callbacks" do
    let(:user) { Factory(:user) }
    
    describe "after_update :update_email_on_zendesk" do
      it "should not delay Module#put if email has not changed" do
        user.zendesk_id = 15483194
        Delayed::Job.last.should be_nil
      end
      
      it "should not delay Module#put if user has no zendesk_id" do
        user.email = "new@email.com"
        user.save
        user.email.should == "new@email.com"
        Delayed::Job.last.should be_nil
      end
      
      it "should delay Module#put if the user has a zendesk_id and his email has changed" do
        user.zendesk_id = 15483194
        user.email      = "new@email.com"
        user.save
        user.email.should == "new@email.com"
        Delayed::Job.last.name.should == 'Module#put'
      end
      
      it "should update user's email on Zendesk if this user has a zendesk_id and his email has changed" do
        user.zendesk_id = 15483194
        user.email      = "new@email.com"
        user.save
        VCR.use_cassette("user/update_email_on_zendesk") { @worker.work_off }
        Delayed::Job.last.should be_nil
        VCR.use_cassette("user/email_on_zendesk_after_update") do
          JSON.parse(Zendesk.get("/users/15483194/user_identities.json").body).select { |h| h["identity_type"] == "email" }.map { |h| h["value"] }.should include("new@email.com")
        end
      end
    end
    
    describe "after_update :charge_failed_invoices" do
      context "with no failed invoices" do
        it "should not delay Class#charge" do
          user.cc_updated_at = Time.now.utc
          user.save
          Delayed::Job.last.should be_nil
        end
      end
      
      context "with failed invoices" do
        before(:all) do
          @user = Factory(:user)
          Factory(:invoice, :user => @user, :state => 'paid', :started_at => Time.utc(2010,1), :ended_at => Time.utc(2010,2))
          Factory(:invoice, :user => @user, :state => 'failed', :started_at => Time.utc(2010,2), :ended_at => Time.utc(2010,3))
          Factory(:invoice, :user => @user, :state => 'failed', :started_at => Time.utc(2010,3), :ended_at => Time.utc(2010,4))
        end
        subject { @user }
        
        it "should not delay Class#charge if cc_updated_at has not changed" do
          subject.reload.country = 'FR'
          lambda { subject.save }.should_not change(Delayed::Job, :count)
        end
        
        it "should delay Class#charge if the user has failed invoices and cc_updated_at has changed" do
          subject.reload.cc_updated_at = Time.now.utc
          lambda { subject.save }.should change(Delayed::Job, :count).by(2)
          Delayed::Job.last.name.should == 'Class#charge'
        end
        
        context "with a suspended user" do
          before(:all) { subject.reload.update_attribute(:state, 'suspended') }
          
          it "should delay Class#charge if the user has failed invoices and cc_updated_at has changed" do
            subject.cc_updated_at = Time.now.utc
            lambda { subject.save }.should change(Delayed::Job, :count).by(2)
            Delayed::Job.last.name.should == 'Class#charge'
          end
        end
      end
    end
  end
  
  describe "attributes accessor" do
    describe "email=" do
      it "should downcase email" do
        user = Factory.build(:user, :email => "BOB@cool.com")
        user.email.should == "bob@cool.com"
      end
    end
  end
  
  describe "Instance Methods" do
    let(:user) { Factory(:user) }
    
    describe "#active?" do
      it "should be active when suspended in order to allow login" do
        user.suspend
        user.should be_active
      end
      it "should be active when beta in order to allow login" do
        user.update_attribute(:state, 'beta')
        user.should be_active
      end
    end
    
    describe "#delay_suspend_and_set_suspending_delayed_job_id" do
      before(:all) { @user = Factory(:user) }
      subject { @user.reload.delay_suspend_and_set_suspending_delayed_job_id }
      
      it "should delay suspend user" do
        lambda { subject }.should change(Delayed::Job, :count).by(1)
        Delayed::Job.last.name.should == "Class#suspend"
      end
      
      it "should delay charging in Billing.days_before_suspend_user.days.from_now by default" do
        subject
        Delayed::Job.last.run_at.should be_within(5).of(Billing.days_before_suspend_user.days.from_now) # seconds of tolerance
      end
      
      it "should set suspending_delayed_job_id" do
        @user.reload.suspending_delayed_job_id.should be_nil
        subject
        @user.reload.suspending_delayed_job_id.should == Delayed::Job.last.id
      end
      
      context "giving a custom run_at" do
        specify do
          @user.delay_suspend_and_set_suspending_delayed_job_id(Time.utc(2010,7,24))
          Delayed::Job.last.run_at.should == Time.utc(2010,7,24)
        end
      end
      
      context "with an exception raised by User.delay.suspend" do
        before(:each) do
          User.should_receive(:delay).and_raise("Exception")
          Notify.stub!(:send)
        end
        
        specify { expect { subject }.to_not raise_error }
        
        it "should not delay suspend user" do
          lambda { subject }.should_not change(Delayed::Job, :count)
        end
        it "should Notify of the exception" do
          Notify.should_receive(:send)
          subject
        end
        it "should not set suspending_delayed_job_id" do
          @user.reload.suspending_delayed_job_id.should be_nil
          subject
          @user.reload.suspending_delayed_job_id.should be_nil
        end
      end
    end # #delay_suspend_and_set_suspending_delayed_job_id
    
  end
  
protected
  
  def accept_invitation(attributes = {})
    default = {
      :password => "123456",
      :first_name => "John",
      :last_name => "Doe",
      :country => "CH",
      :postal_code => "2000",
      :use_company => true,
      :company_name => "bob",
      :company_url => "bob.com",
      :company_job_title => "Boss",
      :company_employees => "101-1'000",
      :company_videos_served => "0-1'000",
      :terms_and_conditions => "1",
      :invitation_token => @user.invitation_token
    }
    User.accept_invitation(default.merge(attributes))
  end
  
end





# == Schema Information
#
# Table name: users
#
#  id                        :integer         not null, primary key
#  state                     :string(255)
#  email                     :string(255)     default(""), not null
#  encrypted_password        :string(128)     default(""), not null
#  password_salt             :string(255)     default(""), not null
#  confirmation_token        :string(255)
#  confirmed_at              :datetime
#  confirmation_sent_at      :datetime
#  reset_password_token      :string(255)
#  remember_token            :string(255)
#  remember_created_at       :datetime
#  sign_in_count             :integer         default(0)
#  current_sign_in_at        :datetime
#  last_sign_in_at           :datetime
#  current_sign_in_ip        :string(255)
#  last_sign_in_ip           :string(255)
#  failed_attempts           :integer         default(0)
#  locked_at                 :datetime
#  cc_type                   :string(255)
#  cc_last_digits            :integer
#  cc_expire_on              :date
#  cc_updated_at             :datetime
#  created_at                :datetime
#  updated_at                :datetime
#  invitation_token          :string(20)
#  invitation_sent_at        :datetime
#  zendesk_id                :integer
#  enthusiast_id             :integer
#  first_name                :string(255)
#  last_name                 :string(255)
#  postal_code               :string(255)
#  country                   :string(255)
#  use_personal              :boolean
#  use_company               :boolean
#  use_clients               :boolean
#  company_name              :string(255)
#  company_url               :string(255)
#  company_job_title         :string(255)
#  company_employees         :string(255)
#  company_videos_served     :string(255)
#  suspending_delayed_job_id :integer
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

