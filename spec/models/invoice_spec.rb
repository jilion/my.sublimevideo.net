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
      Factory(:site, :user => @user, :loader_hits_cache => 100000)
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
      @user  = Factory(:user, :trial_ended_at => 3.month.ago)
      @site1 = Factory(:site, :user => @user, :loader_hits_cache => 1000, :player_hits_cache => 11)
      @site2 = Factory(:site, :user => @user, :loader_hits_cache => 50, :player_hits_cache => 5, :hostname => "google.com")
    end
    
    subject { Invoice.current(@user) }
    
    it { subject.reference.should be_nil } # not working with its...
    its(:started_on)    { should == Time.now.utc.to_date }
    its(:ended_on)      { should == Time.now.utc.to_date + 1.month }
    its(:sites)         { should be_kind_of(Invoice::Sites) }
    its(:user)          { should be_present }
    its(:amount)        { should == 1066 }
    its(:sites_amount)  { should == 1066 }
    its(:videos_amount) { should == 0 }
    it { should be_current }
  end
  
  describe "validations" do
    
    it "should validates started_on < 1.month.ago" do
      user    = Factory(:user, :last_invoiced_on => 1.day.ago)
      invoice = Factory.build(:invoice, :user => user)
      invoice.should_not be_valid
      invoice.errors[:started_on].should be_present
    end
    it "should validates ended_on < Date.today" do
      user    = Factory(:user, :next_invoiced_on => 1.day.from_now)
      invoice = Factory.build(:invoice, :user => user)
      invoice.should_not be_valid
      invoice.errors[:ended_on].should be_present
    end
    
    describe "amount < minimum.amount" do
      before(:each) do
        @user = Factory(:user, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago)
        @site = Factory(:site, :user => @user, :loader_hits_cache => User::Trial.free_loader_hits + 100, :player_hits_cache => 11)
        @invoice = Factory.build(:invoice, :user => @user)
      end
      
      it "should not validates amount" do
        @invoice.should_not be_valid
        @invoice.errors[:amount].should be_present
      end
      
      it "should update user.next_invoiced_on to next month" do
        @invoice.should_not be_valid
        @user.reload.next_invoiced_on.should == (1.day.ago + 1.month).to_date
      end
    end
    
  end
  
  describe "callbacks" do
    
    it "should set started_on from user.last_invoiced_on" do
      user = Factory(:user, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago).reload
      Factory(:site, :user => user, :loader_hits_cache => 100000)
      invoice = Factory(:invoice, :user => user)
      invoice.started_on.should == 2.month.ago.to_date
    end
    it "should set started_on from user.created_at if user.last_invoiced_on is nil" do
      user = Factory(:user, :last_invoiced_on => nil, :created_at => 2.month.ago, :next_invoiced_on => 1.day.ago).reload
      Factory(:site, :user => user, :loader_hits_cache => 100000)
      invoice = Factory(:invoice, :user => user)
      invoice.started_on.should == user.created_at.to_date
    end
    it "should set ended_on from user.next_invoiced_on" do
      user = Factory(:user, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago).reload
      Factory(:site, :user => user, :loader_hits_cache => 100000)
      invoice = Factory(:invoice, :user => user)
      invoice.ended_on.should == 1.day.ago.to_date
    end
    
    it "should update user invoiced dates after create" do
      user = Factory(:user, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago).reload
      Factory(:site, :user => user, :loader_hits_cache => 100000)
      invoice = Factory(:invoice, :user => user)
      user.reload
      user.last_invoiced_on.should == invoice.ended_on
      user.next_invoiced_on.should == invoice.ended_on + 1.month
    end
    
    it "should clear user limit_alert_email_sent_at date" do
      user = Factory(:user, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago, :limit_alert_email_sent_at => 3.day.ago)
      Factory(:site, :user => user, :loader_hits_cache => 100000)
      Factory(:invoice, :user => user)
      
      user.reload.limit_alert_email_sent_at.should be_nil
    end
    
    context "second invoice" do
      before(:each) do
        @user  = Factory(:user, :trial_ended_at => 3.month.ago, :invoices_count => 1, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago).reload
        @site1 = Factory(:site, :user => @user)
        @site2 = Factory(:site, :user => @user, :hostname => "google.com")
        VCR.use_cassette('one_saved_logs') do
          @log = Factory(:log_voxcast, :started_at => 1.month.ago, :ended_at => 1.month.ago + 3.days)
        end
        Factory(:site_usage, :site => @site1, :log => @log, :loader_hits => 1000100, :player_hits => 15)
        Factory(:site_usage, :site => @site2, :log => @log, :loader_hits => 53, :player_hits => 7)
        Site.update_counters(@site1, :loader_hits_cache => -100, :player_hits_cache => -4) # set a diff between log & cache
        Site.update_counters(@site2, :loader_hits_cache => -3, :player_hits_cache => -2) # set a diff between log & cache
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
      
      it "should reset sites hits caches" do
        VCR.use_cassette('one_saved_logs') do
          @log = Factory(:log_voxcast, :started_at => 2.minutes.ago, :ended_at => 1.minutes.ago)
        end
        Factory(:site_usage, :site => @site1, :log => @log, :loader_hits => 12, :player_hits => 21)
        Factory(:site_usage, :site => @site2, :log => @log, :loader_hits => 23)
        Factory(:invoice, :user => @user)
        Invoice.current(@user).sites.loader_hits.should == 35
        Invoice.current(@user).sites.player_hits.should == 21
      end
      
      it "should delete user current_invoice cache" do
        Rails.cache.should_receive(:delete).with("user_#{@user.id}.current_invoice")
        Factory(:invoice, :user => @user)
      end
      
      describe "when calculate" do
        before(:each) do
          ActionMailer::Base.deliveries.clear
          @invoice = Factory(:invoice, :user => @user).reload # problem if not reloaded, but don't fucking know why!
          @invoice.calculate
        end
        
        subject { @invoice }
        
        it { should be_ready }
        its(:amount)        { should == 1000175 }
        its(:sites_amount)  { should == 1000175 }
        its(:videos_amount) { should == 0 }
        
        it "should sent a email" do
          last_delivery = ActionMailer::Base.deliveries.last
          last_delivery.from.should == ["noreply@sublimevideo.net"]
          last_delivery.to.should include subject.user.email
          last_delivery.subject.should include "Invoice ready to be charged"
          last_delivery.body.should include "$10001.75"
        end
      end
      
    end
    
  end
  
  describe "instance method" do
    
    describe "include_date?" do
      subject { Factory.build(:invoice, :started_on => 30.days.ago, :ended_on => Date.today) }
      
      it { subject.include_date?(20.days.ago).should be_true }
      it { subject.include_date?(20.days.from_now).should be_false }
      
    end
  end
  
end