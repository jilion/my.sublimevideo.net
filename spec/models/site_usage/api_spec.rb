require 'spec_helper'

describe SiteUsage::Api do
  before(:all) do
    @site = Factory(:site)
    @site_usage1 = Factory(:site_usage, site_id: @site.id, day: 61.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
    @site_usage2 = Factory(:site_usage, site_id: @site.id, day: 59.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
    @site_usage3 = Factory(:site_usage, site_id: @site.id, day: Time.now.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
  end
  subject { @site_usage }

  it "selects a subset of fields, as a hash" do
    hash = subject.to_api

    hash.should be_a(Hash)
    hash[:video_pageviews].should == 'huge_plan'
    hash[:title].should == 'Huge Plan'
    hash[:cycle].should == 'month'
    hash[:video_pageviews].should have_key(strftime(59.days.ago.midnight, "%Y-%m-%d"))
  end
end
