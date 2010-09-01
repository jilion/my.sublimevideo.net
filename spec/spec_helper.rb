require 'rubygems'
require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require File.dirname(__FILE__) + "/../config/environment" unless defined?(Rails)
  require 'rspec/rails'
  require 'shoulda'
end

Spork.each_run do
  Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
  
  VCR.config do |c|
    c.cassette_library_dir     = 'spec/fixtures/vcr_cassettes'
    c.http_stubbing_library    = :webmock # or :fakeweb
    c.default_cassette_options = { :record => :new_episodes }
  end
  
  RSpec.configure do |config|
    config.include Shoulda::ActionController::Matchers
    
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
    
    config.mock_with :rspec
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    
    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, comment the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true
    
    # Clear MongoDB Collection
    config.before :each do
      Mongoid.master.collections.select { |c| c.name !~ /system/ }.each(&:drop)
    end
  end
  
end