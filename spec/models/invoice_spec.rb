# == Schema Information
#
# Table name: invoices
#
#  id            :integer         not null, primary key
#  user_id       :integer
#  reference     :string(255)
#  state         :string(255)
#  charged_at    :datetime
#  started_on    :date
#  ended_on      :date
#  amount        :integer         default(0)
#  sites_amount  :integer         default(0)
#  videos_amount :integer         default(0)
#  sites         :text
#  videos        :text
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe Invoice do
  
  context "with valid attributes" do
    before(:each) do
      @user = Factory(:user, :last_invoiced_on => (1.month + 1.day).ago, :next_invoiced_on => 1.day.ago)
    end
    
    subject { Factory(:invoice, :user => @user).reload } # reload needed to have Time as Date
    
    its(:reference)  { should =~ /^[ABCDEFGHIJKLMNPQRSTUVWXYZ1-9]{8}$/ }
    its(:started_on) { should == (1.month + 1.day).ago.utc.to_date }
    its(:ended_on)   { should == 1.day.ago.utc.to_date }
    it { should be_pending }
    it { should be_valid }
  end
  
  context "current, without free trial" do
    before(:each) do
      @user  = Factory(:user, :invoices_count => 1)
      @site1 = Factory(:site, :user => @user, :loader_hits_cache => 100, :player_hits_cache => 11)
      @site2 = Factory(:site, :user => @user, :loader_hits_cache => 50, :player_hits_cache => 5, :hostname => "google.com")
    end
    
    subject { Invoice.current(@user) }
    
    it { subject.reference.should be_nil } # not working with its...
    its(:started_on)    { should == Time.now.utc.to_date }
    its(:ended_on)      { should == Time.now.utc.to_date + 1.month }
    its(:sites)         { should be_kind_of(Invoice::Sites) }
    its(:user)          { should be_present }
    its(:amount)        { should == 166 }
    its(:sites_amount)  { should == 166 }
    its(:videos_amount) { should == 0 }
    it { should be_current }
  end
  
  describe "validations" do
    
    it "should validate started_on < 1.month.ago" do
      user    = Factory(:user, :last_invoiced_on => 1.day.ago)
      invoice = Factory.build(:invoice, :user => user)
      invoice.should_not be_valid
      invoice.errors[:started_on].should be_present
    end
    it "should validate ended_on < Date.today" do
      user    = Factory(:user, :next_invoiced_on => 1.day.from_now)
      invoice = Factory.build(:invoice, :user => user)
      invoice.should_not be_valid
      invoice.errors[:ended_on].should be_present
    end
    
  end
  
  describe "callbacks" do
    
    it "should set started_on from user.last_invoiced_on" do
      user    = Factory(:user, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago)
      invoice = Factory(:invoice, :user => user)
      invoice.reload
      invoice.started_on.should == 2.month.ago.to_date
    end
    it "should set started_on from user.created_at if user.last_invoiced_on is nil" do
      user    = Factory(:user, :last_invoiced_on => nil, :created_at => 2.month.ago, :next_invoiced_on => 1.day.ago)
      invoice = Factory(:invoice, :user => user)
      invoice.reload
      invoice.started_on.should == user.created_at.to_date
    end
    it "should set ended_on from user.next_invoiced_on" do
      user    = Factory(:user, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago)
      invoice = Factory(:invoice, :user => user)
      invoice.reload
      invoice.ended_on.should == 1.day.ago.to_date
    end
    
    it "should update user invoiced dates after create" do
      user    = Factory(:user, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago)
      invoice = Factory(:invoice, :user => user)
      user.reload
      invoice.reload
      user.last_invoiced_on.should == invoice.ended_on
      user.next_invoiced_on.should == invoice.ended_on + 1.month
    end
    
    context "second invoice" do
      before(:each) do
        @user   = Factory(:user, :invoices_count => 1, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago)
        @site1 = Factory(:site, :user => @user, :loader_hits_cache => 100, :player_hits_cache => 11)
        @site2 = Factory(:site, :user => @user, :loader_hits_cache => 50, :player_hits_cache => 5, :hostname => "google.com")
        @current_invoice = Invoice.current(@user)
      end
      
      describe "should clone sites/videos & amount from current_invoice as estimation" do
        
        subject { Factory(:invoice, :user => @user) }
        
        its(:sites)         { should == @current_invoice.sites }
        its(:amount)        { should == @current_invoice.amount }
        its(:sites_amount)  { should == @current_invoice.sites_amount }
        its(:videos_amount) { should == @current_invoice.videos_amount }
        it { should be_pending }
      end
      
    end
    
  end
  
end