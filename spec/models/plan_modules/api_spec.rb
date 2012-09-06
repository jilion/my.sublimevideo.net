require 'spec_helper'

describe PlanModules::Api do
  let(:plan) { create(:plan, name: 'huge_plan', cycle: 'month', video_views: 1_000_000) }
  let(:response) { plan.as_api_response(:v1_self_private) }

  it "selects a subset of fields, as a hash" do
    response.should be_a(Hash)
    response[:name].should == 'huge_plan'
    response[:cycle].should == 'month'
    response[:video_views].should == 1_000_000
  end
end
