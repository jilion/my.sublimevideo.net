require 'spec_helper'

describe InvoiceItem::Overage do
  
  describe ".build(attributes = {})" do
    set(:user)    { Factory(:user) }
    set(:plan)    { Factory(:plan, :price => 1000, :overage_price => 100, :player_hits => 2000) }
    set(:invoice) { Factory(:invoice, :user => user, :started_at => Time.utc(2010,2).beginning_of_month, :ended_at => Time.utc(2010,2).end_of_month) }
    
    context "with a site activated before this month and not archived" do
      set(:site1) { site = Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,1,15)) }
      before(:each) { set_site_usages(site1) }
      subject { InvoiceItem::Overage.build(:site => site1, :invoice => invoice) }
      
      specify { site1.activated_at.to_i.should == Time.utc(2010,1,15).to_i }
      specify { site1.archived_at.to_i.should == 0 }
      
      its(:item)                      { should == site1.plan }
      its(:price)                     { should == site1.plan.overage_price }
      its(:info)                      { should == { :plan_player_hits => 2000, :player_hits_used => 1500 * 3 } }
      its(:overage_blocks)            { should == 3 }
      its(:prorated_plan_player_hits) { should == 2000 }
      its(:minutes)                   { should == 28 * 24 * 60 }
      its(:percentage)                { should == (28 / 28.0).round(2) }
      its(:amount)                    { should == 100 * 3 }
      specify                         { subject.started_at.to_i.should == invoice.started_at.to_i }
      specify                         { subject.ended_at.to_i.should == invoice.ended_at.to_i }
    end
    
    context "with a site activated before this month and archived" do
      set(:site2) { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,1,15), :archived_at => Time.utc(2010,2,15)) }
      before(:each) { set_site_usages(site2) }
      subject { InvoiceItem::Overage.build(:site => site2, :invoice => invoice) }
      
      specify { site2.activated_at.to_i.should == Time.utc(2010,1,15).to_i }
      specify { site2.archived_at.to_i.should == Time.utc(2010,2,15).to_i }
      
      its(:item)                      { should == site2.plan }
      its(:price)                     { should == site2.plan.overage_price }
      its(:info)                      { should == { :plan_player_hits => 2000, :player_hits_used => 1500 * 2 } }
      its(:overage_blocks)            { should == 2 }
      its(:prorated_plan_player_hits) { should == 2000 * 0.5 }
      its(:minutes)                   { should == 14 * 24 * 60 }
      its(:percentage)                { should == (14 / 28.0).round(2) }
      its(:amount)                    { should == 100 * 2 }
      specify                         { subject.started_at.to_i.should == invoice.started_at.to_i }
      specify                         { subject.ended_at.to_i.should == subject.site.archived_at.to_i }
    end
    
    context "with a site activated during the month and not archived" do
      set(:site3) { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,2,20)) }
      before(:each) { set_site_usages(site3) }
      subject { InvoiceItem::Overage.build(:site => site3, :invoice => invoice) }
      
      specify { site3.activated_at.to_i.should == Time.utc(2010,2,20).to_i }
      specify { site3.archived_at.to_i.should == 0 }
      
      its(:item)                      { should == site3.plan }
      its(:price)                     { should == site3.plan.overage_price }
      its(:info)                      { should == { :plan_player_hits => 2000, :player_hits_used => 1500 * 1 } }
      its(:overage_blocks)            { should == 1 }
      its(:prorated_plan_player_hits) { should == 2000 * 0.32 }
      its(:minutes)                   { should == 9 * 24 * 60 }
      its(:percentage)                { should == (9 / 28.0).round(2) }
      its(:amount)                    { should == 100 * 1 }
      specify                         { subject.started_at.to_i.should == subject.site.activated_at.to_i }
      specify                         { subject.ended_at.to_i.should == invoice.ended_at.to_i }
    end
    
    context "with a site activated and archived during the month" do
      set(:site4) { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,2,15), :archived_at => Time.utc(2010,2,20)) }
      before(:each) { set_site_usages(site4) }
      subject { InvoiceItem::Overage.build(:site => site4, :invoice => invoice) }
      
      specify { site4.activated_at.to_i.should == Time.utc(2010,2,15).to_i }
      specify { site4.archived_at.to_i.should == Time.utc(2010,2,20).to_i }
      
      its(:item)                      { should == site4.plan }
      its(:price)                     { should == site4.plan.overage_price }
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
      set(:site5) { Factory(:site, :user => user, :plan => plan, :activated_at => Time.utc(2010,2,2), :archived_at => Time.utc(2010,2,14)) }
      before(:each) { set_site_usages(site5) }
      subject { InvoiceItem::Overage.build(:site => site5, :invoice => invoice) }
      
      specify { site5.activated_at.to_i.should == Time.utc(2010,2,2).to_i }
      specify { site5.archived_at.to_i.should == Time.utc(2010,2,14).to_i }
      
      its(:item)                      { should == site5.plan }
      its(:price)                     { should == site5.plan.overage_price }
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
