# coding: utf-8
require 'spec_helper'

feature "API" do
  before(:all) do
    @user        = Factory(:user)
    @site        = Factory(:site, user: @user)
    @application = Factory(:client_application, user: @user)
    @token       = Factory(:oauth2_token, user: @user, client_application: @application)
  end
  before(:each) do
    @parsed_body = nil
  end

  describe "Passing token" do

    context "Authorized token" do
      describe "2 ways to pass OAuth token" do
        it "is possible to pass OAuth token with the access_token param" do
          visit '/api/test_request?access_token=' + @token.token
          page.driver.status_code.should eql 200
        end

        it "is possible to pass OAuth token with the oauth_token param" do
          visit '/api/test_request?oauth_token=' + @token.token
          page.driver.status_code.should eql 200
        end

        it "is possible to pass OAuth token in the Authorization header" do
          page.driver.header 'Authorization', 'OAuth ' + @token.token
          visit '/api/test_request'
          page.driver.status_code.should eql 200
        end
      end
    end

    context "Non-Authorized token" do
      describe "2 ways to pass OAuth token" do
        it "is possible to pass OAuth token with the access_token param" do
          visit '/api/test_request?access_token=foo'
          page.driver.status_code.should eql 401
          parsed_body['error'].should eql "Unauthorized!"
        end

        it "is possible to pass OAuth token with the oauth_token param" do
          visit '/api/test_request?oauth_token=foo'
          page.driver.status_code.should eql 401
          parsed_body['error'].should eql "Unauthorized!"
        end

        it "is possible to pass OAuth token in the Authorization header" do
          page.driver.header 'Authorization', 'OAuth foo'
          visit '/api/test_request'
          page.driver.status_code.should eql 401
          parsed_body['error'].should eql "Unauthorized!"
        end
      end
    end

  end

  context "Authorized token" do

    describe "Default format" do
      describe "with no extension" do
        scenario do
          visit '/api/test_request?oauth_token=' + @token.token

          page.driver.status_code.should eql 200
          page.driver.response_headers['Content-Type'].should eql "application/json; charset=utf-8"
        end
      end
    end

    describe "JSON" do
      describe "with the .json extension" do
        scenario do
          visit '/api/test_request.json?oauth_token=' + @token.token

          page.driver.status_code.should eql 200
          page.driver.response_headers['Content-Type'].should eql "application/json; charset=utf-8"
        end
      end

      describe "with the right Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+json'
          visit '/api/test_request?oauth_token=' + @token.token

          page.driver.status_code.should eql 200
          page.driver.response_headers['Content-Type'].should eql "application/json; charset=utf-8"
        end
      end
    end # JSON

    describe "XML" do
      describe "with the .xml extension" do
        scenario do
          visit '/api/test_request.xml?oauth_token=' + @token.token

          page.driver.status_code.should eql 200
          page.driver.response_headers['Content-Type'].should eql "application/xml; charset=utf-8"
        end
      end

      describe "with the right Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+xml'
          visit '/api/test_request?oauth_token=' + @token.token

          page.driver.status_code.should eql 200
          page.driver.response_headers['Content-Type'].should eql "application/xml; charset=utf-8"
        end
      end
    end # XML

  end

end

def parsed_body
  @parsed_body ||= JSON[page.source]
end