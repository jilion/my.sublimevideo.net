require 'spec_helper'

describe Api::V1::SitesController do
  before(:all) do
    @site = Factory(:site)
    @api_token = Factory(:api_token, user: @site.user)
  end
  before(:each) { request.env['devise.mapping'] = Devise.mappings[:api_token] }

  context "no auth_token given" do
    it "responds with 401" do
      get :index, :format => :json

      response.status.should == 401
    end
  end

  describe "authentication methods" do
    context "with an authentication_token given through HTTP_AUTHORIZATION headers" do
      before(:each) { request.env['HTTP_AUTHORIZATION'] = "Basic #{ActiveSupport::Base64.encode64("#{@api_token.authentication_token}:X")}" }

      it "responds with 200" do
        get :index, { :format => :json }

        response.status.should == 200
      end
    end

    context "with an authentication_token given through query string" do
      it "responds with 200" do
        get :index, :auth_token => @api_token.authentication_token, :format => :json

        response.status.should == 200
      end
    end
  end

  context "api_token user is authenticated" do
    before(:each) { request.env['HTTP_AUTHORIZATION'] = "Basic #{ActiveSupport::Base64.encode64("#{@api_token.authentication_token}:X")}" }

    it "responds to JSON" do
      get :index, :format => :json

      response.status.should == 200
    end

    it "doesn't respond to XML" do
      get :index, :format => :xml

      response.status.should == 406
    end

    describe "GET /api/1/sites.json" do
      it "responds with a JSON array of hashes" do
        get :index, :format => :json

        parsed_body = JSON[response.body]
        parsed_body.should be_instance_of(Array)
        parsed_body[0].should be_instance_of(Hash)
      end
    end

    describe "GET /api/1/sites/:id.json" do
      it "responds with a JSON array" do
        get :show, :id => @site.token, :format => :json

        JSON[response.body].should be_instance_of(Hash)
      end
    end

    describe "GET /api/1/sites/:id/usage.json" do
      it "responds with a JSON array" do
        get :usage, :id => @site.token, :format => :json

        JSON[response.body].should be_instance_of(Hash)
      end
    end
  end

end
