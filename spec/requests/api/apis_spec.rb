# coding: utf-8
require 'spec_helper'

feature "API" do
  before(:all) do
    @user        = create(:user)
    @site        = create(:site, user: @user)
    @application = create(:client_application, user: @user)
    @token       = create(:oauth2_token, user: @user, client_application: @application)
  end
  after(:all) { DatabaseCleaner.clean_with(:truncation) }

  before do
    @parsed_body = nil
  end

  describe "Not passing token" do
    it "returns an '401 Unauthorized' response" do
      go 'api', 'test_request'
      page.driver.status_code.should eq 401
      parsed_body['error'].should eq "Unauthorized!"
    end
  end

  describe "Passing token" do

    context "Authorized token" do
      describe "2 ways to pass OAuth token" do
        it "is possible to pass OAuth token with the oauth_token param" do
          go 'api', "test_request?oauth_token=#{@token.token}"
          page.driver.status_code.should eq 200
        end

        it "is possible to pass OAuth token in the Authorization header" do
          page.driver.header 'Authorization', "OAuth #{@token.token}"
          go 'api', 'test_request'
          page.driver.status_code.should eq 200
        end
      end
    end

    context "Non-Authorized token" do
      describe "2 ways to pass OAuth token" do
        it "is possible to pass OAuth token with the oauth_token param" do
          go 'api', 'test_request?oauth_token=foo'
          page.driver.status_code.should eq 401
          parsed_body['error'].should eq "Unauthorized!"
        end

        it "is possible to pass OAuth token in the Authorization header" do
          page.driver.header 'Authorization', 'OAuth foo'
          go 'api', 'test_request'
          page.driver.status_code.should eq 401
          parsed_body['error'].should eq "Unauthorized!"
        end
      end
    end

  end

  context "Authorized token" do
    background do
      page.driver.header 'Authorization', "OAuth #{@token.token}"
    end

    describe "Default format" do
      scenario do
        go 'api', 'test_request'

        page.driver.status_code.should eq 200
        page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
      end
    end

    describe "Extensions has precedence over Accept header" do
      scenario do
        page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+json'
        go 'api', 'test_request.xml'

        page.driver.status_code.should eq 200
        page.driver.response_headers['Content-Type'].should eq "application/xml; charset=utf-8"
      end

      scenario do
        page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+xml'
        go 'api', 'test_request.json'

        page.driver.status_code.should eq 200
        page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
      end
    end

    describe "Wrong format" do
      describe "with extension" do
        scenario do
          expect { go 'api', 'test_request.foo' }.to raise_error
        end
      end

      describe "with complete Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+foo'
          go 'api', 'test_request'

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end
      end

      describe "with incomplete Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1'
          go 'api', 'test_request'

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end

        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo'
          go 'api', 'test_request'

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end

        scenario do
          page.driver.header 'Accept', 'application/vnd.sublime'
          go 'api', 'test_request'

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end
      end
    end

    describe "JSON" do
      describe "with the .json extension" do
        scenario do
          go 'api', "test_request.json?oauth_token=#{@token.token}"

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end
      end

      describe "with the right Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+json'
          go 'api', "test_request?oauth_token=#{@token.token}"

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end
      end
    end # JSON

    describe "XML" do
      describe "with the .xml extension" do
        scenario do
          go 'api', "test_request.xml?oauth_token=#{@token.token}"

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/xml; charset=utf-8"
        end
      end

      describe "with the right Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+xml'
          go 'api', "test_request?oauth_token=#{@token.token}"

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/xml; charset=utf-8"
        end
      end
    end # XML

  end

end

feature "legacy routes API" do
  before(:all) do
    @user        = create(:user)
    @site        = create(:site, user: @user)
    @application = create(:client_application, user: @user)
    @token       = create(:oauth2_token, user: @user, client_application: @application)
  end
  after(:all) { DatabaseCleaner.clean_with(:truncation) }

  before do
    @parsed_body = nil
  end

  describe "Not passing token" do
    it "returns an '401 Unauthorized' response" do
      go 'my', 'api/test_request'
      page.driver.status_code.should eq 401
      parsed_body['error'].should eq "Unauthorized!"
    end
  end

  describe "Passing token" do

    context "Authorized token" do
      describe "2 ways to pass OAuth token" do
        it "is possible to pass OAuth token with the oauth_token param" do
          go 'my', "api/test_request?oauth_token=#{@token.token}"
          page.driver.status_code.should eq 200
        end

        it "is possible to pass OAuth token in the Authorization header" do
          page.driver.header 'Authorization', "OAuth #{@token.token}"
          go 'my', 'api/test_request'
          page.driver.status_code.should eq 200
        end
      end
    end

    context "Non-Authorized token" do
      describe "2 ways to pass OAuth token" do
        it "is possible to pass OAuth token with the oauth_token param" do
          go 'my', 'api/test_request?oauth_token=foo'
          page.driver.status_code.should eq 401
          parsed_body['error'].should eq "Unauthorized!"
        end

        it "is possible to pass OAuth token in the Authorization header" do
          page.driver.header 'Authorization', 'OAuth foo'
          go 'my', 'api/test_request'
          page.driver.status_code.should eq 401
          parsed_body['error'].should eq "Unauthorized!"
        end
      end
    end

  end

  context "Authorized token" do
    background do
      page.driver.header 'Authorization', "OAuth #{@token.token}"
    end

    describe "Default format" do
      scenario do
        go 'my', 'api/test_request'

        page.driver.status_code.should eq 200
        page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
      end
    end

    describe "Extensions has precedence over Accept header" do
      scenario do
        page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+json'
        go 'my', 'api/test_request.xml'

        page.driver.status_code.should eq 200
        page.driver.response_headers['Content-Type'].should eq "application/xml; charset=utf-8"
      end

      scenario do
        page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+xml'
        go 'my', 'api/test_request.json'

        page.driver.status_code.should eq 200
        page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
      end
    end

    describe "Wrong format" do
      describe "with extension" do
        scenario do
          expect { go 'my', 'api/test_request.foo' }.to raise_error
        end
      end

      describe "with complete Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+foo'
          go 'my', 'api/test_request'

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end
      end

      describe "with incomplete Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1'
          go 'my', 'api/test_request'

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end

        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo'
          go 'my', 'api/test_request'

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end

        scenario do
          page.driver.header 'Accept', 'application/vnd.sublime'
          go 'my', 'api/test_request'

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end
      end
    end

    describe "JSON" do
      describe "with the .json extension" do
        scenario do
          go 'my', "api/test_request.json?oauth_token=#{@token.token}"

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end
      end

      describe "with the right Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+json'
          go 'my', "api/test_request?oauth_token=#{@token.token}"

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/json; charset=utf-8"
        end
      end
    end # JSON

    describe "XML" do
      describe "with the .xml extension" do
        scenario do
          go 'my', "api/test_request.xml?oauth_token=#{@token.token}"

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/xml; charset=utf-8"
        end
      end

      describe "with the right Accept header" do
        scenario do
          page.driver.header 'Accept', 'application/vnd.sublimevideo-v1+xml'
          go 'my', "api/test_request?oauth_token=#{@token.token}"

          page.driver.status_code.should eq 200
          page.driver.response_headers['Content-Type'].should eq "application/xml; charset=utf-8"
        end
      end
    end # XML

  end

end

def parsed_body
  @parsed_body ||= JSON[page.source]
end