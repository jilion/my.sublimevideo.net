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
#

require 'spec_helper'

describe User do
  let(:user) { Factory(:user) }
  
  context "with valid attributes" do
    subject { user }
    
    its(:terms_and_conditions) { should be_true }
    its(:full_name)        { should == "Joe Blow" }
    its(:email)            { should match /email\d+@user.com/ }
    its(:invoices_count)   { should == 0 }
    its(:last_invoiced_on) { should be_nil }
    its(:next_invoiced_on) { should == Time.now.utc.to_date + 1.month }
    it { should be_valid }
  end
  
  describe "validates" do
    it "should validate presence of full_name" do
      user = Factory.build(:user, :full_name => nil)
      user.should_not be_valid
      user.should have(1).error_on(:full_name)
    end
    it "should validate presence of email" do
      user = Factory.build(:user, :email => nil)
      user.should_not be_valid
      user.should have(2).error_on(:email)
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
        user.should have(2).error_on(:email)
      end
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
  
end