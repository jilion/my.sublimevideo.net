require 'spec_helper'

describe Invoice::Sites do
  
  context "from cache, with free trial reduction" do
    
    before(:each) do
      @user    = Factory(:user)
      @site1   = Factory(:site, :user => @user, :loader_hits_cache => User::Trial.free_loader_hits + 100, :player_hits_cache => User::Trial.free_player_hits + 11)
      @site2   = Factory(:site, :user => @user, :loader_hits_cache => 50, :player_hits_cache => 5, :hostname => "google.com")
    end
    
    subject { Invoice.current(@user).sites }
    
    its(:amount)        { should == 166 }
    its(:loader_amount) { should == 150 }
    its(:player_amount) { should == 16 }
    its(:loader_hits)   { should == 10150 }
    its(:player_hits)   { should == 2016 }
    it "should return site array" do
      subject.should == [
        { :id => @site1.id, :hostname => @site1.hostname, :archived_at => nil, :loader_amount => 10100, :player_amount => 2011, :loader_hits => 10100, :player_hits => 2011},
        { :id => @site2.id, :hostname => @site2.hostname, :archived_at => nil, :loader_amount => 50, :player_amount => 5, :loader_hits => 50, :player_hits => 5}
      ]
    end
  end
  
  context "from cache" do
    
    before(:each) do
      @user    = Factory(:user, :trial_ended_at => 3.month.ago)
      @site1   = Factory(:site, :user => @user, :loader_hits_cache => 100, :player_hits_cache => 11)
      @site2   = Factory(:site, :user => @user, :loader_hits_cache => 50, :player_hits_cache => 5, :hostname => "google.com")
    end
    
    subject { Invoice.current(@user).sites }
    
    its(:amount)        { should == 166 }
    its(:loader_amount) { should == 150 }
    its(:player_amount) { should == 16 }
    its(:loader_hits)   { should == 150 }
    its(:player_hits)   { should == 16 }
    it "should return site array" do
      subject.should == [
        { :id => @site1.id, :hostname => @site1.hostname, :archived_at => nil, :loader_amount => 100, :player_amount => 11, :loader_hits => 100, :player_hits => 11},
        { :id => @site2.id, :hostname => @site2.hostname, :archived_at => nil, :loader_amount => 50, :player_amount => 5, :loader_hits => 50, :player_hits => 5}
      ]
    end
  end
  
  context "from logs" do
    
    before(:each) do
      @user  = Factory(:user, :trial_ended_at => 3.month.ago, :invoices_count => 1, :last_invoiced_on => 2.month.ago, :next_invoiced_on => 1.day.ago).reload
      @site1 = Factory(:site, :user => @user)
      @site2 = Factory(:site, :user => @user, :hostname => "google.com")
      VCR.use_cassette('one_saved_logs') do
        @log = Factory(:log_voxcast, :started_at => 1.month.ago, :ended_at => 1.month.ago + 3.days)
      end
      Factory(:site_usage, :site => @site1, :log => @log, :loader_hits => 1000100, :player_hits => 15)
      Factory(:site_usage, :site => @site2, :log => @log, :loader_hits => 53, :player_hits => 7)
      @invoice = Factory(:invoice, :user => @user).reload # problem if not reloaded, but don't fucking know why!
    end
    
    subject { Invoice::Sites.new(@invoice) }
    
    its(:amount)        { should == 1000175 }
    its(:loader_amount) { should == 1000153 }
    its(:player_amount) { should == 22 }
    its(:loader_hits)   { should == 1000153 }
    its(:player_hits)   { should == 22 }
    it "should return site array" do
      subject.should == [
        { :id => @site1.id, :hostname => @site1.hostname, :archived_at => nil, :loader_amount => 1000100, :player_amount => 15, :loader_hits => 1000100, :player_hits => 15},
        { :id => @site2.id, :hostname => @site2.hostname, :archived_at => nil, :loader_amount => 53, :player_amount => 7, :loader_hits => 53, :player_hits => 7}
      ]
    end
  end
  
end