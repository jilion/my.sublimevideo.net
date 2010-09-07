# == Schema Information
#
# Table name: users
#
#  id                                    :integer         not null, primary key
#  state                                 :string(255)
#  email                                 :string(255)     default(""), not null
#  encrypted_password                    :string(128)     default(""), not null
#  password_salt                         :string(255)     default(""), not null
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
#  next_invoiced_on                      :date
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
#  zendesk_id                            :integer
#  enthusiast_id                         :integer
#  first_name                            :string(255)
#  last_name                             :string(255)
#  postal_code                           :string(255)
#  country                               :string(255)
#  use_personal                          :boolean
#  use_company                           :boolean
#  use_clients                           :boolean
#  company_name                          :string(255)
#  company_url                           :string(255)
#  company_job_title                     :string(255)
#  company_employees                     :string(255)
#  company_videos_served                 :string(255)
#

require 'spec_helper'

describe User do
  let(:user) { Factory(:user) }
  
  context "with valid attributes" do
    subject { user }
    
    its(:terms_and_conditions) { should be_true }
    its(:first_name)           { should == "John" }
    its(:last_name)            { should == "Doe" }
    its(:full_name)            { should == "John Doe" }
    its(:country)              { should == "CH" }
    its(:postal_code)          { should == "2000" }
    its(:use_personal)         { should be_true }
    its(:email)                { should match /email\d+@user.com/ }
    its(:invoices_count)       { should == 0 }
    its(:last_invoiced_on)     { should be_nil }
    its(:next_invoiced_on)     { should == Time.now.utc.to_date + 1.month }
    it { should be_valid }
  end
  
  describe "validates" do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:postal_code) }
    it { should validate_presence_of(:email) }
    
    it "should validate email" do
      user = Factory.build(:user, :email => "beurk")
      user.should_not be_valid
      user.should have(1).error_on(:email)
    end
    it "should validate password length" do
      user = Factory.build(:user, :password => "short")
      user.should_not be_valid
      user.should have(1).error_on(:password)
    end
    
    it "should validate acceptance of terms_and_conditions" do
      user = Factory.build(:user, :terms_and_conditions => false)
      user.should_not be_valid
      user.should have(1).error_on(:terms_and_conditions)
    end
    
    context "with already the email in db" do
      before(:each) { @user = user }
      
      it "should validate uniqueness of email" do
        user = Factory.build(:user, :email => @user.email)
        user.should_not be_valid
        user.should have(1).error_on(:email)
      end
    end
  end
  
  context "already confirmed" do
    subject do 
      user = Factory(:user, :confirmed_at => Time.now)
      User.find(user.id) # hard reload
    end
    
    it { should be_confirmed }
    
    it "should be able to update his first_name" do
      subject.update_attributes(:first_name => 'bob').should be_true
    end
  end
  
  context "invited" do
    before(:each) do
      User.attr_accessible << "enthusiast_id"
      @user = User.invite(:email => "bob@bob.com", :enthusiast_id => 12)
      User.attr_accessible.delete "enthusiast_id"
    end
    subject { @user }
    
    it { should be_invited }
    its(:enthusiast_id) { should == 12 }
    
    it "should not be able to update enthusiast_id" do
      subject.update_attributes(:enthusiast_id => 13)
      subject.enthusiast_id.should == 12
    end
    
    it "should validate password length" do
      user = accept_invitation(:password => "short")
      user.should have(1).error_on(:password)
    end
    
    it "should validate presence of a least once use" do
      user = accept_invitation(:use_company => nil)
      user.should have(1).error_on(:use)
    end
    
    it "should validate company fields if use_company is checked" do
      user = accept_invitation(:company_name => nil, :company_url => nil, :company_job_title => nil, :company_employees => nil, :company_videos_served => nil)
      user.should have(1).error_on(:company_name)
      user.should have(1).error_on(:company_url)
      user.should have(1).error_on(:company_job_title)
      user.should have(1).error_on(:company_employees)
      user.should have(1).error_on(:company_videos_served)
    end
    
    it "should validate company url if use_company is checked" do
      user = accept_invitation(:company_name => nil)
      user.should have(1).error_on(:company_name)
    end
    
    it "should validate acceptance of terms_and_conditions" do
      user = accept_invitation(:terms_and_conditions => "0")
      user.should have(1).error_on(:terms_and_conditions)
    end
    
    it "should be valid" do
      user = accept_invitation
      user.should be_valid
    end
  end
  
  describe "callbacks" do
  end
  
  describe "State Machine" do
    
    describe "initial state" do
      subject { user }
      it { should be_active }
    end
    
    # ===========
    # = suspend =
    # ===========
    describe "event(:suspend) { transition :active => :suspended }" do
      before(:each) { VCR.insert_cassette('user/suspend') }
      
      let(:site1)  { Factory(:site, :user => user, :hostname => "rymai.com")   }
      let(:site2)  { Factory(:site, :user => user, :hostname => "octavez.com") }
      
      it "should set the state as :suspended from :active" do
        user.should be_active
        user.suspend
        user.should be_suspended
      end
      
      describe "callbacks" do
        describe "before_transition :on => :suspend, :do => :suspend_sites" do
          it "should suspend each user' site" do
            site1.should_not be_suspended
            site2.should_not be_suspended
            user.suspend
            site1.reload.should be_suspended
            site2.reload.should be_suspended
          end
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
    # =============
    # = unsuspend =
    # =============
    describe "event(:unsuspend) { transition :suspended => :active }" do
      before(:each) do
        @site1  = Factory(:site, :user => user, :hostname => "rymai.com")
        @site2  = Factory(:site, :user => user, :hostname => "octavez.com")
        VCR.use_cassette('user/suspend') { user.suspend }
        VCR.insert_cassette('user/unsuspend')
      end
      
      it "should set the state as :active from :suspended" do
        user.should be_suspended
        user.unsuspend
        user.should be_active
      end
      
      describe "callbacks" do
        describe "before_transition :on => :unsuspend, :do => :unsuspend_sites" do
          it "should suspend each user' site" do
            @site1.reload.should be_suspended
            @site2.reload.should be_suspended
            user.unsuspend
            @site1.reload.should_not be_suspended
            @site2.reload.should_not be_suspended
          end
        end
      end
      
      after(:each) { VCR.eject_cassette }
    end
    
  end
  
  describe "callbacks" do
    describe "after_update :update_email_on_zendesk" do
      it "should not delay Module#put if email has not changed" do
        user.zendesk_id = 15483194
        user.save
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
        user.reload.email.should == "new@email.com"
        VCR.use_cassette("user/update_email_on_zendesk") { Delayed::Worker.new(:quiet => true).work_off }
        Delayed::Job.last.should be_nil
        VCR.use_cassette("user/email_on_zendesk_after_update") do
          JSON.parse(Zendesk.get("/users/15483194/user_identities.json").body).select{ |h| h["identity_type"] == "email" }.map { |h| h["value"] }.should include "new@email.com"
        end
      end
    end
  end
  
  describe "instance methods" do
    it "should be welcome if sites is empty" do
      user.should be_welcome
    end
    
    it "shouldn't be welcome if user as a credit_card" do
      user.stub(:credit_card?).and_return(true)
      user.should_not be_welcome
    end
    
    it "should be active when suspended to allow login" do
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