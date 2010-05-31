require 'spec_helper'
require 'steak'
require 'capybara/rails'

# require 'capybara/envjs'
# Capybara.default_driver = :envjs

Rspec.configure do |config|
  config.include Capybara
  
  config.after(:each) do
    Capybara.reset_sessions!
  end
end

# Put your acceptance spec helpers inside /spec/acceptance/support
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
