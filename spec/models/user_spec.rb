require 'spec_helper'

# before refactoring: 18.52s
# after refactoring:  11.06s
# 1.67x faster
describe User do
  set(:user) { Factory(:user) }
  before(:each) { Delayed::Job.delete_all }
  
  # before refactoring let: 5.72s
  # after refactoring set:  2.01s
  # 2.84x faster
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
    it { should have_many :sites }
    it { should have_many :invoices }
    
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
      user.errors[:use].should == ["Please check at least one option"]
    end
    
    context "use_company is checked" do
      it "should validate company fields if use_company is checked" do
        fields = [:company_name, :company_url, :company_job_title, :company_employees, :company_videos_served]
        user = Factory.build(:user, Hash[fields.map { |f| [f, nil] }].merge({ :use_personal => false, :use_company => true }))
        user.should_not be_valid
        fields.each do |f|
          user.errors[f].should == ["can't be blank"]
        end
      end
      
      it "should validate company url" do
        user = Factory.build(:user, :use_company => true, :company_url => "http://localhost")
        user.should_not be_valid
        user.errors[:company_url].should == ["is invalid"]
      end
    end
  end
  
  context "invited" do
    subject { Factory(:user).tap { |u| u.send(:attributes=, { :invitation_token => '123', :invitation_sent_at => Time.now, :email => "bob@bob.com", :enthusiast_id => 12 }, false); u.save(:validate => false) } }
    
    its(:enthusiast_id) { should == 12 }
    
    it { should be_invited }
    
    it "should not be able to update enthusiast_id" do
      subject.update_attributes(:enthusiast_id => 13)
      subject.enthusiast_id.should == 12
    end
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
        @site1 = Factory(:site, :user => user, :hostname => "rymai.com")
        @site2 = Factory(:site, :user => user, :hostname => "octavez.com")
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
    it "should be active when suspended to allow login" do
      user.suspend
      user.should be_active
    end
    
    it "should downcase email" do
      user = Factory.build(:user, :email => "BOB@cool.com")
      user.email.should == "bob@cool.com"
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
#  id                    :integer         not null, primary key
#  state                 :string(255)
#  email                 :string(255)     default(""), not null
#  encrypted_password    :string(128)     default(""), not null
#  password_salt         :string(255)     default(""), not null
#  confirmation_token    :string(255)
#  confirmed_at          :datetime
#  confirmation_sent_at  :datetime
#  reset_password_token  :string(255)
#  remember_token        :string(255)
#  remember_created_at   :datetime
#  sign_in_count         :integer         default(0)
#  current_sign_in_at    :datetime
#  last_sign_in_at       :datetime
#  current_sign_in_ip    :string(255)
#  last_sign_in_ip       :string(255)
#  failed_attempts       :integer         default(0)
#  locked_at             :datetime
#  invoices_count        :integer         default(0)
#  last_invoiced_on      :date
#  next_invoiced_on      :date
#  cc_type               :string(255)
#  cc_last_digits        :integer
#  cc_expire_on          :date
#  cc_updated_at         :datetime
#  video_settings        :text
#  created_at            :datetime
#  updated_at            :datetime
#  invitation_token      :string(20)
#  invitation_sent_at    :datetime
#  zendesk_id            :integer
#  enthusiast_id         :integer
#  first_name            :string(255)
#  last_name             :string(255)
#  postal_code           :string(255)
#  country               :string(255)
#  use_personal          :boolean
#  use_company           :boolean
#  use_clients           :boolean
#  company_name          :string(255)
#  company_url           :string(255)
#  company_job_title     :string(255)
#  company_employees     :string(255)
#  company_videos_served :string(255)
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

