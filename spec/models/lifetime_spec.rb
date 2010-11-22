require 'spec_helper'

describe Lifetime do
  context "from factory" do
    set(:lifetime_from_factory) { Factory(:lifetime) }
    subject { lifetime_from_factory }
    
    its(:site)       { should be_present }
    its(:item)       { should be_present }
    its(:created_at) { should be_present }
    its(:deleted_at) { should be_nil }
    
    it { be_valid }
  end
  
  describe "associations" do
    set(:lifetime_for_associations) { Factory(:lifetime) }
    subject { lifetime_for_associations }
    
    it { should belong_to :site }
    it { should belong_to :item }
  end
  
  describe ".addons_minutes_uptime" do
    set(:user) { Factory(:user) }
    set(:site1) { Factory(:site, :user => user) }
    set(:site2) { Factory(:site, :user => user) }
    set(:addon_lifetime1) { Factory(:lifetime, :site => site1, :created_at => Time.utc(2010,1,15)) }
    set(:addon_lifetime2) { Factory(:lifetime, :site => site1, :created_at => Time.utc(2010,2,20), :deleted_at => Time.utc(2010,2,25,23,59,59)) }
    set(:addon_lifetime3) { Factory(:lifetime, :site => site2, :created_at => Time.utc(2010,1,15), :deleted_at => Time.utc(2010,2,15,23,59,59)) }
    set(:addon_lifetime4) { Factory(:lifetime, :site => site2, :created_at => Time.utc(2010,2,20)) }
    
    it "should return the user's lifetimes of this month billable items" do
      lifetimes = Lifetime.addons_minutes_uptime(user, 2010, 2)
      
      lifetimes[0].should == { :type => "site", :site_id => site1.id, :addon_id => addon_lifetime1.item_id, :started_at => Time.utc(2010,2), :ended_at => Time.utc(2010,2,28,23,59,59), :minutes => 28.days / 1.minute }
      lifetimes[1].should == { :type => "site", :site_id => site1.id, :addon_id => addon_lifetime2.item_id, :started_at => Time.utc(2010,2,20,0,0), :ended_at => Time.utc(2010,2,25,23,59,59), :minutes => 6.days / 1.minute }
      lifetimes[2].should == { :type => "site", :site_id => site2.id, :addon_id => addon_lifetime3.item_id, :started_at => Time.utc(2010,2), :ended_at => Time.utc(2010,2,15,23,59,59), :minutes => (15.days / 1.minute) }
      lifetimes[3].should == { :type => "site", :site_id => site2.id, :addon_id => addon_lifetime4.item_id, :started_at => Time.utc(2010,2,20), :ended_at => Time.utc(2010,2,28,23,59,59), :minutes => (9.days / 1.minute) }
    end
  end
  
  describe ".seconds_to_minutes(seconds)" do
    it "should return 0 minutes for 0 seconds" do
      Lifetime.seconds_to_minutes(0).should == 0
    end
    
    it "should return 1 minute from 1 second to 60 seconds" do
      Lifetime.seconds_to_minutes(1).should == 1
      Lifetime.seconds_to_minutes(60).should == 1
    end
    
    it "should return 2 minutes from 61 seconds to 120 seconds" do
      Lifetime.seconds_to_minutes(61).should == 2
      Lifetime.seconds_to_minutes(120).should == 2
    end
    
    it "should return 60 minutes for 3600 seconds" do
      Lifetime.seconds_to_minutes(3600).should == 60
    end
    
    it "should return 61 minutes for 3601 seconds" do
      Lifetime.seconds_to_minutes(3601).should == 61
    end
  end
end

# == Schema Information
#
# Table name: lifetimes
#
#  id         :integer         not null, primary key
#  site_id    :integer
#  item_type  :string(255)
#  item_id    :integer
#  created_at :datetime
#  deleted_at :datetime
#
# Indexes
#
#  index_lifetimes_created_at  (site_id,item_type,item_id,created_at)
#  index_lifetimes_deleted_at  (site_id,item_type,item_id,deleted_at) UNIQUE
#

