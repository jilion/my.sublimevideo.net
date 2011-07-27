# coding: utf-8
require 'spec_helper'

feature "Sites API" do
  before(:all) do
    @user        = Factory(:user)
    @site        = Factory(:site, user: @user)
    @application = Factory(:client_application, user: @user)
    @token       = Factory(:oauth2_token, user: @user, client_application: @application)
  end
  before(:each) do
    @parsed_body = nil
  end

  describe "/api/sites" do
    scenario do
      visit '/api/sites?access_token=' + @token.token

      parsed_body.should be_kind_of(Hash)
      parsed_body["sites"].should be_kind_of(Array)
      parsed_body["sites"][0].should be_kind_of(Hash)
    end
  end

  describe "/api/sites/:token" do
    scenario "existing site token" do
      visit "/api/sites/#{@site.token}?access_token=" + @token.token

      parsed_body.should be_kind_of(Hash)
      parsed_body['site'].should be_kind_of(Hash)
      parsed_body['site']['token'].should eql @site.token
    end

    scenario "non-existing site token" do
      visit "/api/sites/abc123?access_token=" + @token.token

      page.driver.status_code.should eql 404
      page.driver.response_headers['Content-Type'].should eql "application/json; charset=utf-8"
      parsed_body['error'].should eql "Site with token 'abc123' could not be found."
    end
  end

  describe "/api/1/sites/:token/usage" do
    background do
      @site_usage1 = Factory(:site_usage, site_id: @site.id, day: 61.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
      @site_usage2 = Factory(:site_usage, site_id: @site.id, day: 59.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
      @site_usage3 = Factory(:site_usage, site_id: @site.id, day: Time.now.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
    end

    scenario do
      visit "/api/sites/#{@site.token}/usage.json?access_token=" + @token.token

      parsed_body.should be_kind_of(Hash)
      parsed_body["site"].should be_kind_of(Hash)
      parsed_body["site"]["token"].should eql @site.token
      parsed_body["site"]["usage"].should be_kind_of(Array)
      parsed_body["site"]["usage"][0]["day"].should eql @site_usage2.day.strftime("%Y-%m-%d")
      parsed_body["site"]["usage"][0]["video_pageviews"].should eql @site_usage2.billable_player_hits
      parsed_body["site"]["usage"][1]["day"].should eql @site_usage3.day.strftime("%Y-%m-%d")
      parsed_body["site"]["usage"][1]["video_pageviews"].should eql @site_usage3.billable_player_hits
    end
  end

end

def parsed_body
  @parsed_body ||= JSON[page.source]
end