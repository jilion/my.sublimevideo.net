require 'spec_helper'

describe Invoice::Sites do
  
  context "from cache" do
    
    before(:each) do
      @user    = Factory(:user, :last_invoiced_at => 1.day.ago, :next_invoiced_at => 1.day.from_now)
      @invoice = Factory(:invoice, :user => @user)
      @site1   = Factory(:site, :user => @user, :loader_hits_cache => 100, :js_hits_cache => 11)
      @site2   = Factory(:site, :user => @user, :loader_hits_cache => 50, :js_hits_cache => 5, :hostname => "google.com")
    end
    
    subject { Invoice::Sites.new(@invoice, :from_cache => true) }
    
    it { subject.amount.should == 166 }
    it { subject.loader_amount.should == 150 }
    it { subject.js_amount.should == 16 }
    it { subject.loader_hits.should == 150 }
    it { subject.js_hits.should == 16 }
    it "should return site array" do
      subject.should == [
        { :id => @site1.id, :hostname => @site1.hostname, :loader_amount => 100, :js_amount => 11, :loader_hits => 100, :js_hits => 11},
        { :id => @site2.id, :hostname => @site2.hostname, :loader_amount => 50, :js_amount => 5, :loader_hits => 50, :js_hits => 5}
      ]
    end
  end
  
end