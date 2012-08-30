require 'spec_helper'

describe SiteUsageModules::Api do
  let(:site) { create(:site) }
  let(:site_usage) { create(:site_usage, site_id: site.id, day: 61.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400) }
  let(:response) { site_usage.as_api_response(:v1_private_self) }

  it "selects a subset of fields, as a hash" do
    response.should be_a(Hash)
    response[:day].should == site_usage.day.strftime("%Y-%m-%d")
    response[:video_views].should == 2700
  end
end
