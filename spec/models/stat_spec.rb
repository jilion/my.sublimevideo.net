require 'spec_helper'

describe Stat::SiteUsage do
  before(:each) do
    @site1 = Factory(:site)
    @site2 = Factory(:site)
    @day1  = Time.utc(2010, 1, 1)
    @day2  = Time.utc(2010, 1, 2)
    @day3  = Time.utc(2010, 1, 3)
    @day4  = Time.utc(2010, 1, 4)
    Factory(:site_usage, :day => @day1, :site_id => @site1.id, :player_hits => 1)
    Factory(:site_usage, :day => @day2, :site_id => @site2.id, :player_hits => 2)
    Factory(:site_usage, :day => @day3, :site_id => @site1.id, :player_hits => 3)
    Factory(:site_usage, :day => @day4, :site_id => @site2.id, :player_hits => 4)
  end
  
  describe "Class Methods" do
    describe ".usages" do
      context "without a site_id given" do
        subject { Stat::SiteUsage.timeline(@day1, @day2) }
        
        it "should return a hash" do
          subject.should be_is_a(Hash)
        end
        
        context "return a hash" do
          it "of size 16" do
            subject.size.should == 16
          end
          
          it "which should contain a key 'all_usage' with 1 as a value for the first day" do
            subject["all_usage"][0].should == 1
            subject["all_usage"][1].should == 2
          end
        end
      end
      
      context "with a site_id given" do
        subject { Stat::SiteUsage.timeline(@day1, @day3, site_id: @site1.id) }
        
        it "should return a hash" do
          subject.should be_is_a(Hash)
        end
        
        context "return a hash" do
          it "of size 16" do
            subject.size.should == 16
          end
          
          it "which should contain a first hash with 1 as a value for the key 'all_usage'" do
            subject["all_usage"][0].should == 1
            subject["all_usage"][1].should == 0
            subject["all_usage"][2].should == 3
          end
        end
        
      end
    end
  end
end

describe Stat::Invoice do
  before(:each) do
    @user1 = Factory(:user)
    @user2 = Factory(:user)
    @day1  = Time.utc(2010, 1, 1)
    @day2  = Time.utc(2010, 1, 31)
    @day3  = Time.utc(2010, 2, 1)
    @day4  = Time.utc(2010, 2, 28)
    Factory(:invoice, user: @user1, state: 'open',   started_at: 36.hours.ago, ended_at: @day2, amount: 1000)
    Factory(:invoice, user: @user2, state: 'paid',   started_at: 36.hours.ago, ended_at: @day2, amount: 1200)
    Factory(:invoice, user: @user1, state: 'failed', started_at: 20.hours.ago, ended_at: @day4, amount: 2000)
    Factory(:invoice, user: @user2, state: 'failed', started_at: 20.hours.ago, ended_at: @day4, amount: 2400)
  end
  
  describe "Class Methods" do
    describe ".usages" do
      context "without a user_id given" do
        subject { Stat::Invoice.timeline(@day1, @day4) }
        
        it "should return an array" do
          subject.should be_is_a(Array)
        end
        
        context "return an array" do
          it "of size 2" do
            subject.size.should == 2
          end
          
          it "which should contain the invoice amount per month" do
            subject[0].should == 2200
            subject[1].should == 4400
          end
        end
      end
      
      context "with a user_id given" do
        subject { Stat::Invoice.timeline(@day1, @day4, user_id: @user1.id) }
        
        it "should return a array" do
          subject.should be_is_a(Array)
        end
        
        context "return a hash" do
          it "of size 2" do
            subject.size.should == 2
          end
          
          it "which should contain the invoice amount per month" do
            subject[0].should == 1000
            subject[1].should == 2000
          end
        end
        
      end
    end
  end
  
end