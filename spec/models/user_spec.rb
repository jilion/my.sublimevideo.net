require 'spec_helper'

# before refactoring: 18.52s
# after refactoring:  11.06s
# 1.67x faster
describe User do
  
  context "from factory" do
    set(:user_from_factory) { Factory(:user) }
    subject { user_from_factory }
    
    its(:terms_and_conditions) { should be_true }
    its(:first_name)           { should == "John" }
    its(:last_name)            { should == "Doe" }
    its(:full_name)            { should == "John Doe" }
    its(:country)              { should == "CH" }
    its(:postal_code)          { should == "2000" }
    its(:use_personal)         { should be_true }
    its(:email)                { should match /email\d+@user.com/ }
    its(:invoices_count)       { should == 0 }
    # its(:last_invoiced_on)     { should be_nil }
    its(:billable_on)     { should be_nil }
    
    it { should be_valid }
  end
  
  describe "associations" do
    set(:user_for_associations) { Factory(:user) }
    subject { user_for_associations }
    
    it { should have_many :sites }
    it { should have_many :invoices }
    
    # it "should have_one last_invoice" do
    #   user     = Factory(:user)
    #   invoice1 = Factory(:invoice, :user => user, :amount => 1, :state => 'ready', :ended_on => 3.days.ago)
    #   invoice2 = Factory(:invoice, :user => user, :amount => 1, :state => 'ready', :ended_on => 2.days.ago)
    #   user.reload.last_invoice.should == invoice2
    # end
    
    it "should have_one open_invoice" do
      user    = Factory(:user)
      invoice = Factory(:invoice, :user => user)
      user.reload.open_invoice.should == invoice
    end
  end
  
  describe "scope" do
    
    describe "billable_on" do
      before(:each) do
        Timecop.travel(Date.new(2010,1,15).to_time.utc)
        @user_billable_yesterday     = Factory(:user).tap { |u| u.update_attribute(:billable_on, Time.now.utc - 1.day) }
        @user_billable_today         = Factory(:user).tap { |u| u.update_attribute(:billable_on, Time.now.utc) }
        @user_billable_tomorrow      = Factory(:user).tap { |u| u.update_attribute(:billable_on, Time.now.utc + 1.day) }
        @user_trial_ending_yesterday = Factory(:user)
        @user_trial_ending_today     = Factory(:user)
        @user_trial_ending_tomorrow  = Factory(:user)
        Factory(:site, :user => @user_trial_ending_yesterday).tap { |u| u.update_attribute(:activated_at, Time.now.utc - Billing.trial_days - 1.day) }
        Factory(:site, :user => @user_trial_ending_today).tap { |u| u.update_attribute(:activated_at, Time.now.utc - Billing.trial_days) }
        Factory(:site, :user => @user_trial_ending_tomorrow).tap { |u| u.update_attribute(:activated_at, Time.now.utc - Billing.trial_days + 1.day) }
      end
      after(:each) { Timecop.return }
      
      specify do
        users = User.billable_on(Time.now.utc.to_date)
        users.should include(@user_billable_today)
        users.should include(@user_trial_ending_today)
        users.should_not include(@user_billable_tomorrow)
        users.should_not include(@user_billable_yesterday)
        users.should_not include(@user_trial_ending_yesterday)
        users.should_not include(@user_trial_ending_tomorrow)
      end
    end
    
  end
  
  describe "validates " do
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
    
    describe "initial state" do
      subject { user }
      it { should be_active }
    end
    
    # ===========
    # = suspend =
    # ===========
    describe "event(:suspend) { transition :active => :suspended }" do
      let(:site1) { Factory(:site, :user => user, :hostname => "rymai.com").tap { |s| s.update_attribute(:state, 'active') } }
      let(:site2) { Factory(:site, :user => user, :hostname => "octavez.com").tap { |s| s.update_attribute(:state, 'dev') } }
      
      it "should set the state as :suspended from :active" do
        user.should be_active
        user.suspend
        user.should be_suspended
      end
      
      describe "callbacks" do
        describe "before_transition :on => :suspend, :do => :suspend_sites" do
          it "should suspend each user' active site" do
            site1.should be_active
            site2.should be_dev
            user.suspend
            site1.reload.should be_suspended
            site2.reload.should be_dev
          end
        end
      end
    end
    
    # =============
    # = unsuspend =
    # =============
    describe "event(:unsuspend) { transition :suspended => :active }" do
      let(:site1) { Factory(:site, :user => user, :hostname => "rymai.com").tap { |s| s.update_attribute(:state, 'suspended') } }
      let(:site2) { Factory(:site, :user => user, :hostname => "octavez.com").tap { |s| s.update_attribute(:state, 'dev') } }
      before(:each) { user.update_attribute(:state, 'suspended') }
      
      it "should set the state as :active from :suspended" do
        user.should be_suspended
        user.unsuspend
        user.should be_active
      end
      
      describe "callbacks" do
        describe "before_transition :on => :unsuspend, :do => :unsuspend_sites" do
          it "should suspend each user' site" do
            site1.reload.should be_suspended
            site2.reload.should be_dev
            user.unsuspend
            site1.reload.should be_active
            site2.reload.should be_dev
          end
        end
      end
    end
    
  end
  
  # TODO slow: 3s for 4 examples => 0.75s/ex
  describe "callbacks" do
    let(:user) { Factory(:user) }
    
    describe "after_update :update_email_on_zendesk" do
      it "should not delay Module#put if email has not changed" do
        user.zendesk_id = 15483194
        Delayed::Job.last.should be_nil
      end
      
      it "should not delay Module#put if user has no zendesk_id" do
        user.email      = "new@email.com"
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
        VCR.use_cassette("user/update_email_on_zendesk") { Delayed::Worker.new(:quiet => true).work_off }
        Delayed::Job.last.should be_nil
        VCR.use_cassette("user/email_on_zendesk_after_update") do
          JSON.parse(Zendesk.get("/users/15483194/user_identities.json").body).select { |h| h["identity_type"] == "email" }.map { |h| h["value"] }.should include("new@email.com")
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
  
  describe "instance methods" do
    let(:user) { Factory(:user) }
    
    it "should be active when suspended in order to allow login" do
      user.suspend
      user.should be_active
    end
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
#  id                                    :integer         not null, primary key
#  state                                 :string(255)
#  email                                 :string(255)     default(""), not null
#  encrypted_password                    :string(128)     default(""), not null
#  password_salt                         :string(255)     default(""), not null
#  full_name                             :string(255)
#  confirmation_token                    :string(255)
#  confirmed_at                          :datetime
#  confirmation_sent_at                  :datetime
#  reset_password_token                  :string(255)
#  remember_token                        :string(255)
#  remember_created_at                   :datetime
#  sign_in_count                         :integer         default(0)
#  current_sign_in_at                    :datetime
#  last_sign_in_at                       :datetime
#  current_sign_in_ip                    :string(255)
#  last_sign_in_ip                       :string(255)
#  failed_attempts                       :integer         default(0)
#  locked_at                             :datetime
#  invoices_count                        :integer         default(0)
#  last_invoiced_on                      :date
#  billable_on                           :date
#  trial_ended_at                        :datetime
#  trial_usage_information_email_sent_at :datetime
#  trial_usage_warning_email_sent_at     :datetime
#  limit_alert_amount                    :integer         default(0)
#  limit_alert_email_sent_at             :datetime
#  cc_type                               :string(255)
#  cc_last_digits                        :integer
#  cc_expire_on                          :date
#  cc_updated_at                         :datetime
#  video_settings                        :text
#  created_at                            :datetime
#  updated_at                            :datetime
#  invitation_token                      :string(20)
#  invitation_sent_at                    :datetime
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

