require 'spec_helper'

describe Stat::SiteUsage do
  before(:each) do
    @site1 = FactoryGirl.create(:site)
    @site2 = FactoryGirl.create(:site)
    @day1  = Time.utc(2010, 1, 1)
    @day2  = Time.utc(2010, 1, 2)
    @day3  = Time.utc(2010, 1, 3)
    @day4  = Time.utc(2010, 1, 4)
    FactoryGirl.create(:site_usage, :day => @day1, :site_id => @site1.id, :player_hits => 1)
    FactoryGirl.create(:site_usage, :day => @day2, :site_id => @site2.id, :player_hits => 2)
    FactoryGirl.create(:site_usage, :day => @day3, :site_id => @site1.id, :player_hits => 3)
    FactoryGirl.create(:site_usage, :day => @day4, :site_id => @site2.id, :player_hits => 4)
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
            subject.size.should == 20
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
            subject.size.should == 20
          end

          it "which should contain a first hash with 1 as a value for the key 'all_usage'" do
            subject["all_usage"][0].should == 1
            subject["all_usage"][1].should == 2
            subject["all_usage"][2].should == 3
          end
        end

      end
    end
  end
end