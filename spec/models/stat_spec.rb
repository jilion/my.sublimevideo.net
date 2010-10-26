require 'spec_helper'

describe Stat do
  let(:site1) { Factory(:site) }
  let(:site2) { Factory(:site) }
  let(:day1) { Time.utc(2010, 1, 1) }
  let(:day2) { Time.utc(2010, 1, 2) }
  let(:day3) { Time.utc(2010, 1, 3) }
  let(:day4) { Time.utc(2010, 1, 4) }
  
  before(:each) do
    Factory(:site_usage, :day => day1, :site_id => site1.id, :player_hits => 1)
    Factory(:site_usage, :day => day2, :site_id => site2.id, :player_hits => 2)
    Factory(:site_usage, :day => day3, :site_id => site1.id, :player_hits => 3)
    Factory(:site_usage, :day => day4, :site_id => site2.id, :player_hits => 4)
  end
  
  describe "Class Methods" do
    describe ".usages" do
      context "without a site_id given" do
        subject { Stat.usages(day1, day2) }
        
        it "should return an array" do
          subject.should be_is_a(Array)
        end
        
        it "should return an array of size 2" do
          subject.size.should == 2
        end
        
        it "should return an array, which should contain a first hash with the starting day as a value for the key 'day'" do
          subject[0]["day"].should == day1
        end
        
        it "should return an array, which should contain a first hash with 1 as a value for the key 'all_usage'" do
          subject[0]["all_usage"].should == 1
        end
        
        it "should return an array, which should contain a first hash with the ending day as a value for the key 'day'" do
          subject[1]["day"].should == day2
        end
        
        it "should return an array, which should contain a first hash with 2 as a value for the key 'all_usage'" do
          subject[1]["all_usage"].should == 2
        end
      end
      
      context "with a site_id given" do
        subject { Stat.usages(day1, day2, :site_id => site1.id) }
        
        it "should return an array" do
          subject.should be_is_a(Array)
        end
        
        it "should return an array of size 1" do
          subject.size.should == 1
        end
        
        it "should return an array, which should contain a first hash with the starting day as a value for the key 'day'" do
          subject[0]["day"].should == day1
        end
        
        it "should return an array, which should contain a first hash with 1 as a value for the key 'all_usage'" do
          subject[0]["all_usage"].should == 1
        end
      end
    end
  end
  
end