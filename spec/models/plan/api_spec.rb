require 'spec_helper'

describe Plan::Api do
  before(:all) do
    @plan = Factory(:plan, name: 'huge_plan', cycle: 'month', player_hits: 1_000_000)
  end
  subject { @plan }

  it "selects a subset of fields, as a hash" do
    hash = subject.to_api

    hash.should be_a(Hash)
    hash[:name].should == 'huge_plan'
    hash[:title].should == 'Huge Plan'
    hash[:cycle].should == 'month'
    hash[:video_pageviews].should == 1_000_000
  end
end
