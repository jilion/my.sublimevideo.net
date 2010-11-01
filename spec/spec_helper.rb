require 'rubygems'
require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However, 
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  
  ENV["RAILS_ENV"] ||= 'test'
  require File.dirname(__FILE__) + "/../config/environment" unless defined?(Rails)
  require 'rspec/rails'
  require 'shoulda'
  require 'timecop'
  
  # require 'akephalos'
  # Capybara.javascript_driver = :akephalos
  # require 'capybara/envjs'
  # Capybara.javascript_driver = :envjs
end

Spork.each_run do
  # This code will be run each time you run your specs.
  # require 'factory_girl'
  # FactoryGirl.find_definitions
  # Dir[File.expand_path(File.join(File.dirname(__FILE__),'factories','**','*.rb'))].each {|f| require f}
  # 
  Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
  
  VCR.config do |c|
    c.cassette_library_dir     = 'spec/fixtures/vcr_cassettes'
    c.http_stubbing_library    = :webmock # or :fakeweb
    c.default_cassette_options = { :record => :new_episodes }
  end
  
  RSpec.configure do |config|
    config.include(Shoulda::ActionController::Matchers)
    config.include(Capybara)
    
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