require "rubygems"
require "minitest/autorun"
require "pry"
# require "webmock"
# include WebMock::API

$: << File.expand_path("../lib")
require "zendesk"

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.new(fixture_path + "/" + file).readlines.to_s
end

FORMATS = Zendesk::Config::VALID_FORMATS

if ENV["LIVE"] #################################################################

  ENDPOINT = ENV["ZENDESK_API_URI"]
  EMAIL    = ENV["ZENDESK_API_USER"]
  PASSWORD = ENV["ZENDESK_API_PASSWORD"]

else ###########################################################################

  ENDPOINT        = "https://mondocam.zendesk.com"
  EMAIL, PASSWORD = "fruity@pebbles.com", "sekret"
  prefix = "https://mondocam.zendesk.com"

  FORMATS.each do |format|

    # Users
    # ---------------------
    stub_request(:get, %r| #{prefix}/users\.#{format}                     |x).to_return(:body => fixture("users.#{format}"))
    stub_request(:get, %r| #{prefix}/users/\d+\.#{format}                 |x).to_return(:body => fixture("user.#{format}"))
    stub_request(:get, %r| #{prefix}/users/current\.#{format}             |x).to_return(:body => fixture("user_current.#{format}"))
    stub_request(:get, %r| #{prefix}/organizations/\d+/users\.#{format}   |x).to_return(:body => fixture("users_of_org.#{format}"))
    stub_request(:get, %r| #{prefix}/groups/\d+/users\.#{format}          |x).to_return(:body => fixture("users_of_group.#{format}"))
    stub_request(:get, %r| #{prefix}/users\.#{format}\\?query=\w+         |x).to_return(:body => fixture("user_current.#{format}"))
    stub_request(:get, %r| #{prefix}/users\.#{format}\\?query=\w+&role=\d |x).to_return(:body => fixture("user_current.#{format}"))
    stub_request(:get, %r| #{prefix}/users\.#{format}\\?group=\d+         |x).to_return(:body => fixture("users_of_group.#{format}"))
    stub_request(:get, %r| #{prefix}/users\.#{format}\\?organization=\d+  |x).to_return(:body => fixture("users_of_org.#{format}"))

    stub_request(:put, %r| #{prefix}/users/\d+\.#{format}                 |x).to_return(:status => 200)
    # Etc
    # ---------------------

  end
end
