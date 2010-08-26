require 'spec_helper'
require 'steak'
require 'capybara/rails'

Rspec.configure do |config|
  config.include Capybara
  
  config.before(:each) do
    # VCR.insert_cassette('typekit')
  end
  
  config.after(:each) do
    Capybara.reset_sessions!
    # VCR.eject_cassette
  end
end

# Put your acceptance spec helpers inside /spec/acceptance/support
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
