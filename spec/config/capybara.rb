require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/email/rspec'

Capybara.javascript_driver = :webkit
Capybara.server_port = 2999

RSpec.configure do |config|
  config.before do
    Capybara.default_host = "http://sublimevideo.dev"
    Capybara.reset_sessions!
  end
end
