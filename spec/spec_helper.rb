ENV['RAILS_ENV'] ||= 'test'

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require File.dirname(__FILE__) + "/../config/environment"
require 'rspec/rails'

require Rails.root.join('spec/config/carrierwave.rb') # force before order
Dir[Rails.root.join('spec/config/**/*.rb')].each { |f| require f }
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
end
