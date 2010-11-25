require 'spec_helper'

describe InvoiceItem::Overage do
  
  describe ".build(attributes = {})" do
    before(:all) do
      @user    = Factory(:user)
      @plan    = Factory(:plan, :price => 1000, :overage_price => 100, :player_hits => 2000)
      @site    = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15))
      @invoice = Factory(:invoice, :user => @user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month)
    end
    
    describe "shared logic" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15)) }
      subject { InvoiceItem::Overage.build(:site => @site, :invoice => @invoice) }
      
      specify { @site.activated_at.to_i.should == Time.utc(2010,1,15).to_i }
      specify { @site.archived_at.to_i.should == 0 }
      
      its(:item)  { should == @site.plan }
      its(:price) { should == @site.plan.overage_price }
    end
    
    context "with a site activated before this month and not archived" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15)) }
      before(:each) { set_site_usages(@site) }
      subject { InvoiceItem::Overage.build(:site => @site, :invoice => @invoice) }
      
      its(:info)                      { should == { :plan_player_hits => 2000, :player_hits_used => 1500 * 3 } }
      its(:overage_blocks)            { should == 3 }
      its(:prorated_plan_player_hits) { should == 2000 }
      its(:minutes)                   { should == 28 * 24 * 60 }
      its(:percentage)                { should == (28 / 28.0).round(2) }
      its(:amount)                    { should == 100 * 3 }
      specify                         { subject.started_at.to_i.should == subject.invoice.started_at.to_i }
      specify                         { subject.ended_at.to_i.should == subject.invoice.ended_at.to_i }
    end
    
    context "with a site activated before this month and archived" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,1,15), :archived_at => Time.utc(2010,2,15)) }
      before(:each) { set_site_usages(@site) }
      subject { InvoiceItem::Overage.build(:site => @site, :invoice => @invoice) }
      
      its(:info)                      { should == { :plan_player_hits => 2000, :player_hits_used => 1500 * 2 } }
      its(:overage_blocks)            { should == 2 }
      its(:prorated_plan_player_hits) { should == 2000 * 0.5 }
      its(:minutes)                   { should == 14 * 24 * 60 }
      its(:percentage)                { should == (14 / 28.0).round(2) }
      its(:amount)                    { should == 100 * 2 }
      specify                         { subject.started_at.to_i.should == subject.invoice.started_at.to_i }
      specify                         { subject.ended_at.to_i.should == subject.site.archived_at.to_i }
    end
    
    context "with a site activated during the month and not archived" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,20)) }
      before(:each) { set_site_usages(@site) }
      subject { InvoiceItem::Overage.build(:site => @site, :invoice => @invoice) }
      
      its(:info)                      { should == { :plan_player_hits => 2000, :player_hits_used => 1500 * 1 } }
      its(:overage_blocks)            { should == 1 }
      its(:prorated_plan_player_hits) { should == 2000 * 0.32 }
      its(:minutes)                   { should == 9 * 24 * 60 }
      its(:percentage)                { should == (9 / 28.0).round(2) }
      its(:amount)                    { should == 100 * 1 }
      specify                         { subject.started_at.to_i.should == subject.site.activated_at.to_i }
      specify                         { subject.ended_at.to_i.should == subject.invoice.ended_at.to_i }
    end
    
    context "with a site activated and archived during the month" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,15), :archived_at => Time.utc(2010,2,20)) }
      before(:each) { set_site_usages(@site) }
      subject { InvoiceItem::Overage.build(:site => @site, :invoice => @invoice) }
      
      its(:info)                      { should == { :plan_player_hits => 2000, :player_hits_used => 1500 * 2 } }
      its(:overage_blocks)            { should == 3 }
      its(:prorated_plan_player_hits) { should == 2000 * 0.18 }
      its(:minutes)                   { should == 5 * 24 * 60 }
      its(:percentage)                { should == (5 / 28.0).round(2) }
      its(:amount)                    { should == 100 * 3 }
      specify                         { subject.started_at.to_i.should == subject.site.activated_at.to_i }
      specify                         { subject.ended_at.to_i.should == subject.site.archived_at.to_i }
    end
    
    context "with a site activated and archived during the month (without site usages)" do
      before(:all) { @site = Factory(:site, :user => @user, :plan => @plan, :activated_at => Time.utc(2010,2,2), :archived_at => Time.utc(2010,2,14)) }
      before(:each) { set_site_usages(@site) }
      subject { InvoiceItem::Overage.build(:site => @site, :invoice => @invoice) }
      
      its(:info)                      { should == { :plan_player_hits => 2000, :player_hits_used => 1500 * 0 } }
      its(:overage_blocks)            { should == 0 }
      its(:prorated_plan_player_hits) { should == 2000 * 0.43 }
      its(:minutes)                   { should == 12 * 24 * 60 }
      its(:percentage)                { should == (12 / 28.0).round(2) }
      its(:amount)                    { should == 100 * 0 }
      specify                         { subject.started_at.to_i.should == subject.site.activated_at.to_i }
      specify                         { subject.ended_at.to_i.should == subject.site.archived_at.to_i }
    end
    
  end
  
end

def set_site_usages(site)
  player_hits = {
    :main_player_hits => Plan::OVERAGES_PLAYER_HITS_BLOCK/2,
    :main_player_hits_cached => Plan::OVERAGES_PLAYER_HITS_BLOCK/2,
    :extra_player_hits => Plan::OVERAGES_PLAYER_HITS_BLOCK/4,
    :extra_player_hits_cached => Plan::OVERAGES_PLAYER_HITS_BLOCK/4
  } # == 1500 player_hits
  Factory(:site_usage, player_hits.merge(:site_id => site.id, :day => Time.utc(2010,1,15).beginning_of_day))
  Factory(:site_usage, player_hits.merge(:site_id => site.id, :day => Time.utc(2010,2,1).beginning_of_day))
  Factory(:site_usage, player_hits.merge(:site_id => site.id, :day => Time.utc(2010,2,15).beginning_of_day))
  Factory(:site_usage, player_hits.merge(:site_id => site.id, :day => Time.utc(2010,2,20).beginning_of_day))
  Factory(:site_usage, player_hits.merge(:site_id => site.id, :day => Time.utc(2010,3,1).beginning_of_day))
end
