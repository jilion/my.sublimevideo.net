# coding: utf-8
require 'spec_helper'

feature "API /sites" do
  before(:all) do
    @user = Factory(:user)
    @user.create_api_token
    @site = Factory(:site, user: @user)
  end
  before(:each) do
    @parsed_body = nil
  end

  describe "Authentication" do
    describe "HTTP AUTH" do
      scenario do
        page.driver.header 'Authorization', "Basic #{ActiveSupport::Base64.encode64("#{@user.api_token.authentication_token}:X")}"
        visit '/api/1/sites.json'

        page.driver.status_code.should == 200
      end
    end

    describe "QUERY STRING AUTH" do
      scenario do
        visit "/api/1/sites.json?auth_token=#{@user.api_token.authentication_token}"

        page.driver.status_code.should == 200
      end
    end
  end

  describe "/api/1/sites.json" do
    context "not authenticated" do
      scenario do
        visit '/api/1/sites.json'

        page.driver.status_code.should == 401
        parsed_body["request"].should == "/api/1/sites.json"
        parsed_body["error"].should == "You need to sign in or sign up before continuing."
      end
    end

    context "authenticated" do
      scenario do
        visit "/api/1/sites.json?auth_token=#{@user.api_token.authentication_token}"

        parsed_body.should be_kind_of(Hash)
        parsed_body["sites"].should be_kind_of(Array)
        parsed_body["sites"][0].should be_kind_of(Hash)
      end
    end
  end

  describe "/api/1/sites/:token.json" do
    context "not authenticated" do
      scenario do
        visit '/api/1/sites/abc123.json'

        page.driver.status_code.should == 401
        parsed_body["request"].should == "/api/1/sites/abc123.json"
        parsed_body["error"].should == "You need to sign in or sign up before continuing."
      end
    end

    context "authenticated" do
      scenario do
        visit "/api/1/sites/#{@site.token}.json?auth_token=#{@user.api_token.authentication_token}"

        parsed_body.should be_kind_of(Hash)
        parsed_body["site"].should be_kind_of(Hash)
        parsed_body["site"]["token"].should == @site.token
      end
    end
  end

  describe "/api/1/sites/:token/usage.json" do
    context "not authenticated" do
      scenario do
        visit '/api/1/sites/abc123/usage.json'

        page.driver.status_code.should == 401
        parsed_body["request"].should == "/api/1/sites/abc123/usage.json"
        parsed_body["error"].should == "You need to sign in or sign up before continuing."
      end
    end

    context "authenticated" do
      background do
        @site_usage1 = Factory(:site_usage, site_id: @site.id, day: 61.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        @site_usage2 = Factory(:site_usage, site_id: @site.id, day: 59.days.ago.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
        @site_usage3 = Factory(:site_usage, site_id: @site.id, day: Time.now.midnight, main_player_hits: 1000, main_player_hits_cached: 800, extra_player_hits: 500, extra_player_hits_cached: 400)
      end

      scenario do
        visit "/api/1/sites/#{@site.token}/usage.json?auth_token=#{@user.api_token.authentication_token}"

        parsed_body.should be_kind_of(Hash)
        parsed_body["site"].should be_kind_of(Hash)
        parsed_body["site"]["token"].should == @site.token
        parsed_body["site"]["usage"].should be_kind_of(Array)
        parsed_body["site"]["usage"][0]["day"].should == @site_usage2.day.strftime("%Y-%m-%d")
        parsed_body["site"]["usage"][0]["video_pageviews"].should == @site_usage2.billable_player_hits
        parsed_body["site"]["usage"][1]["day"].should == @site_usage3.day.strftime("%Y-%m-%d")
        parsed_body["site"]["usage"][1]["video_pageviews"].should == @site_usage3.billable_player_hits
      end
    end
  end

end

def parsed_body
  @parsed_body ||= JSON[page.source]
end