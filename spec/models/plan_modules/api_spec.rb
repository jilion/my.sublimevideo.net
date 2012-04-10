require 'spec_helper'

describe PlanModules::Api do
  before(:all) do
    @plan     = create(:plan, name: 'huge_plan', cycle: 'month', video_views: 1_000_000)
    @response = @plan.as_api_response(:v1_private_self)
  end

  it "selects a subset of fields, as a hash" do
    @response.should be_a(Hash)
    @response[:name].should == 'huge_plan'
    @response[:cycle].should == 'month'
    @response[:video_views].should == 1_000_000
  end
end
