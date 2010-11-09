require 'rubygems'
require 'spork'
ENV["RAILS_ENV"] ||= 'test'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However, 
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  
  require File.dirname(__FILE__) + "/../config/environment"
  require 'rspec/rails'
  
  # require 'timecop'
  
  # require 'akephalos'
  # Capybara.javascript_driver = :akephalos
  # require 'capybara/envjs'
  # Capybara.javascript_driver = :envjs
  
  VCR.config do |c|
    c.cassette_library_dir     = 'spec/fixtures/vcr_cassettes'
    c.http_stubbing_library    = :webmock # or :fakeweb
    c.default_cassette_options = { :record => :new_episodes }
  end
  
  RSpec.configure do |config|
    config.include Shoulda::ActionController::Matchers
    config.include Capybara
    config.include Devise::TestHelpers, :type => :controller
    
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
    
    config.mock_with :rspec
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    
    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, comment the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = false
    
    config.before(:suite) do
      DatabaseCleaner[:active_record].strategy = :transaction
      DatabaseCleaner[:mongoid].strategy       = :truncation
      DatabaseCleaner.clean_with(:truncation) # clean all the databases
    end
    
    config.before(:all) do
      PaperTrail.enabled = false
    end
    
    config.before(:each) do
      Capybara.reset_sessions!
      DatabaseCleaner.start
    end
    
    # Clear MongoDB Collection
    config.after(:each) do
      DatabaseCleaner.clean
      # Mongoid.master.collections.select { |c| c.name !~ /system/ }.each(&:drop)
    end
    
    config.after(:all) do
      DatabaseCleaner.clean_with(:truncation) # clean all the databases
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.
  
  # Needed to prevent routes.rb to be load on Rails initialization and make User/Admin model loaded by devise_for
  MySublimeVideo::Application.reload_routes!
  
  # Needed to prevent all models loaded by Mongoid
  Rails::Mongoid.load_models(MySublimeVideo::Application)
  
  # Factory need to be required each launch to prevent loading of all models
  require 'factory_girl'
  require Rails.root.join("spec/factories")
  
  Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
end

# --- Instructions ---
# - Sort through your spec_helper file. Place as much environment loading 
#   code that you don't normally modify during development in the 
#   Spork.prefork block.
# - Place the rest under Spork.each_run block
# - Any code that is left outside of the blocks will be ran during preforking
#   and during each_run!
# - These instructions should self-destruct in 10 seconds.  If they don't,
#   feel free to delete them.
#