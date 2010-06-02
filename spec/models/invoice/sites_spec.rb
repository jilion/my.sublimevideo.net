require 'spec_helper'

describe Invoice::Sites do
  
  context "from cache, with free trial reduction" do
    
    before(:each) do
      @user    = Factory(:user)
      @invoice = Factory.build(:invoice, :user => @user, :state => 'current')
      @site1   = Factory(:site, :user => @user, :loader_hits_cache => Trial.free_loader_hits + 100, :player_hits_cache => Trial.free_player_hits + 11)
      @site2   = Factory(:site, :user => @user, :loader_hits_cache => 50, :player_hits_cache => 5, :hostname => "google.com")
    end
    
    subject { Invoice::Sites.new(@invoice, :from_cache => true) }
    
    its(:amount)        { should == 166 }
    its(:loader_amount) { should == 150 }
    its(:player_amount) { should == 16 }
    its(:loader_hits)   { should == 10150 }
    its(:player_hits)   { should == 2016 }
    it "should return site array" do
      subject.should == [
        { :id => @site1.id, :hostname => @site1.hostname, :loader_amount => 10100, :player_amount => 2011, :loader_hits => 10100, :player_hits => 2011},
        { :id => @site2.id, :hostname => @site2.hostname, :loader_amount => 50, :player_amount => 5, :loader_hits => 50, :player_hits => 5}
      ]
    end
  end
  
  context "from cache" do
    
    before(:each) do
      @user    = Factory(:user, :invoices_count => 1)
      @invoice = Factory.build(:invoice, :user => @user, :state => 'current')
      @site1   = Factory(:site, :user => @user, :loader_hits_cache => 100, :player_hits_cache => 11)
      @site2   = Factory(:site, :user => @user, :loader_hits_cache => 50, :player_hits_cache => 5, :hostname => "google.com")
    end
    
    subject { Invoice::Sites.new(@invoice, :from_cache => true) }
    
    its(:amount)        { should == 166 }
    its(:loader_amount) { should == 150 }
    its(:player_amount) { should == 16 }
    its(:loader_hits)   { should == 150 }
    its(:player_hits)   { should == 16 }
    it "should return site array" do
      subject.should == [
        { :id => @site1.id, :hostname => @site1.hostname, :loader_amount => 100, :player_amount => 11, :loader_hits => 100, :player_hits => 11},
        { :id => @site2.id, :hostname => @site2.hostname, :loader_amount => 50, :player_amount => 5, :loader_hits => 50, :player_hits => 5}
      ]
    end
  end
  
end