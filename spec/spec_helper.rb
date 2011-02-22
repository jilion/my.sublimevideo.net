require 'rubygems'
require 'spork'
ENV["RAILS_ENV"] ||= 'test'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  # https://github.com/timcharper/spork/wiki/Spork.trap_method-Jujutsu
  require "rails/mongoid"
  Spork.trap_class_method(Rails::Mongoid, :load_models)
  require "rails/application"
  Spork.trap_method(Rails::Application, :reload_routes!)

  require File.dirname(__FILE__) + "/../config/environment"
  require 'rspec/rails'
  require 'vcr'

  # require 'akephalos'
  # Capybara.javascript_driver = :akephalos
  # require 'capybara/envjs'
  # Capybara.javascript_driver = :envjs

  VCR.config do |config|
    config.stub_with :webmock # or :fakeweb
    config.cassette_library_dir     = 'spec/fixtures/vcr_cassettes'
    config.default_cassette_options = { :record => :new_episodes }
  end

  RSpec.configure do |config|
    config.extend VCR::RSpec::Macros

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
      @worker    = Delayed::Worker.new
      @dev_plan  = Factory(:dev_plan)
      @beta_plan = Factory(:beta_plan)
      @paid_plan = Factory(:plan)
    end

    config.before(:each) do
      Capybara.reset_sessions!
      DatabaseCleaner.start
    end

    # Clear MongoDB Collection
    config.after(:each) do
      DatabaseCleaner.clean
      Delayed::Job.delete_all
      # Mongoid.master.collections.select { |c| c.name !~ /system/ }.each(&:drop)
    end

    config.after(:all) do
      DatabaseCleaner.clean_with(:truncation) # clean all the databases
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

  # Factory need to be required each launch to prevent loading of all models
  require 'factory_girl'
  require Rails.root.join("spec/factories")

  Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

  RSpec.configure do |config|
    config.include Shoulda::ActionController::Matchers
    config.include Capybara
    config.include Devise::TestHelpers, :type => :controller
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
