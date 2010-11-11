require 'spec_helper'

describe Invoice do
  context "from factory" do
    set(:invoice_from_factory) { Factory(:invoice) }
    subject { invoice_from_factory }
    
    its(:user)       { should be_present }
    its(:reference)  { should =~ /^[A-Z1-9]{8}$/ }
    its(:state)      { should == 'current' }
    its(:amount)     { should be_nil }
    its(:started_on) { should == Date.new(2010,1,1) }
    its(:ended_on)   { should == Date.new(2010,1,31) }
    its(:charged_at) { should be_nil }
    its(:attempts)   { should == 0 }
    its(:last_error) { should be_nil }
    its(:failed_at)  { should be_nil }
    
    it { be_valid }
  end
  
  describe "associations" do
    set(:invoice_for_associations) { Factory(:invoice) }
    subject { invoice_for_associations }
    
    it { should belong_to :user }
    it { should have_many :invoice_items }
  end
  
  describe "validates" do
    subject { Factory(:invoice) }
    
    [:user_id, :started_on, :ended_on].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:started_on) }
    it { should validate_presence_of(:ended_on) }
    
    it "should validate presence of amount only if the invoice is in 'ready' state" do
      subject.should be_current
      subject.amount.should be_nil
      subject.should be_valid
      
      subject.state = 'ready'
      
      subject.should be_ready
      subject.amount.should be_nil
      subject.should_not be_valid
      subject.errors[:amount].should == ["can't be blank"]
    end
  end
  
  describe "State Machine" do
    subject { Factory(:invoice) }
    
    describe "initial state" do
      it { should be_current }
    end
    
    describe "prepare_for_charging" do
      before(:each) { subject.amount = 10 }
      
      it "should set state to ready" do
        subject.prepare_for_charging
        subject.should be_ready
      end
    end
    
    describe "archive" do
      before(:each) do
        subject.amount = 10
        subject.prepare_for_charging
      end
      
      it "should set state to archived" do
        subject.archive
        subject.should be_archived
      end
    end
  end
  
  describe "Class methods" do
    describe "billable_users" do
      before(:each) do
        Timecop.travel(Date.new(2010,1,15))
        Billing.stub(:trial_days) { 10 }
        @user_billable_yesterday     = Factory(:user).tap { |u| u.update_attribute(:next_invoiced_on, Date.today - 1) }
        @user_billable_today         = Factory(:user).tap { |u| u.update_attribute(:next_invoiced_on, Date.today) }
        @user_billable_tomorrow      = Factory(:user).tap { |u| u.update_attribute(:next_invoiced_on, Date.today + 1) }
        @user_trial_ending_yesterday = Factory(:user)
        @user_trial_ending_today     = Factory(:user)
        @user_trial_ending_tomorrow  = Factory(:user)
        Factory(:site, :user => @user_trial_ending_yesterday).tap { |u| u.update_attribute(:activated_at, Date.today - Billing.trial_days - 1) }
        Factory(:site, :user => @user_trial_ending_today).tap { |u| u.update_attribute(:activated_at, Date.today - Billing.trial_days) }
        Factory(:site, :user => @user_trial_ending_tomorrow).tap { |u| u.update_attribute(:activated_at, Date.today - Billing.trial_days + 1) }
      end
      after(:each) { Timecop.return }
      
      it "should not return users that have their next_invoiced_on after today" +
         "should return users that have their next_invoiced_on today or before" + 
         "should return users that a nil have next_invoiced_on and with a sites.activated_at + trial_days <= today" do
        users = Invoice.billable_users
        users.should_not include(@user_billable_tomorrow)
        users.should include(@user_billable_yesterday)
        users.should include(@user_billable_today)
        users.should include(@user_trial_ending_yesterday)
        users.should include(@user_trial_ending_today)
      end
    end
  end
end

# == Schema Information
#
# Table name: invoices
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  reference  :string(255)
#  state      :string(255)
#  amount     :integer
#  started_on :date
#  ended_on   :date
#  charged_at :datetime
#  attempts   :integer         default(0)
#  last_error :string(255)
#  failed_at  :datetime
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_invoices_on_user_id  (user_id)
#

