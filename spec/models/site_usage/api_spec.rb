require 'spec_helper'

describe SiteUsage::Api do
  before(:all) do
    @site = Factory(:site)
    @site_usage1 = Factory(:site_usage, site_id: @site.id, day: 61.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
    @site_usage2 = Factory(:site_usage, site_id: @site.id, day: 59.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
    @site_usage3 = Factory(:site_usage, site_id: @site.id, day: Time.now.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
  end
  subject { SiteUsage }

  it "selects a subset of fields, as a hash" do
    hash = subject.to_api(60.days.ago.midnight, Time.now.utc.end_of_day)

    hash.should be_a(Hash)
    hash[@site_usage1.day.strftime("%Y-%m-%d")].should be_nil
    hash[@site_usage2.day.strftime("%Y-%m-%d")].should == @site_usage2.billable_player_hits
    hash[@site_usage3.day.strftime("%Y-%m-%d")].should == @site_usage3.billable_player_hits
  end
end
