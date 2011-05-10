require 'spec_helper'

describe SublimeVideo::API, :type => :controller do
  before(:each) { request.env['devise.mapping'] = Devise.mappings[:api_token] }

  it "should respond with 401 to GET :index" do
    get :index, :format => :json

    response.status.should == 401
  end

  let(:api_token) { Factory(:api_token) }

  context "with an authentication_token given through HTTP_AUTHORIZATION headers" do
    it "should respond with 401 to GET :index" do
      get :index, { :format => :json }, { "Authorization" => "Basic #{ActiveSupport::Base64.encode64("#{api_token.authentication_token}:X")}" }

      response.status.should == 200
    end
  end

  context "with an authentication_token given through query string" do
    it "should respond with 401 to GET :index" do
      get :index, :auth_token => api_token.authentication_token, :format => :json

      response.status.should == 200
    end
  end

end
