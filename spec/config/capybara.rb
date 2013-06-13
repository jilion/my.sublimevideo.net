require 'capybara/rspec'
require 'capybara/rails'
require 'capybara/email/rspec'
require 'capybara/poltergeist'

# http://docs.tddium.com/troubleshooting/browser-based-integration-tests/
def find_available_port
  server = TCPServer.new('lvh.me', 0)
  server.addr[1]
ensure
  server.close if server
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, debug: false, timeout: 60)
end
Capybara.javascript_driver = :poltergeist

# Capybara.server_boot_timeout = 30
Capybara.server_port = find_available_port
Capybara.ignore_hidden_elements = false

RSpec.configure do |config|
  config.before do
    if example.metadata[:js]
      # http://docs.tddium.com/troubleshooting/browser-based-integration-tests
      # http://asciicasts.com/episodes/221-subdomains-in-rails-3
      $capybara_domain = 'lvh.me'
      Capybara.default_host = "http://#{$capybara_domain}:#{Capybara.server_port}"
    else
      $capybara_domain = 'sublimevideo.dev'
      Capybara.default_host = "http://#{$capybara_domain}"
    end
    Capybara.reset_sessions!
  end
end
