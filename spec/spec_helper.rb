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
  Spork.trap_method(Rails::Application::RoutesReloader, :reload!)

  require File.dirname(__FILE__) + "/../config/environment"
  require 'rspec/rails'
  require 'capybara/rspec'
  require 'capybara/rails'
  require 'vcr'

  VCR.config do |config|
    config.stub_with :webmock, :typhoeus
    config.cassette_library_dir     = 'spec/fixtures/vcr_cassettes'
    config.ignore_localhost         = true
    config.default_cassette_options = { :record => :new_episodes }
  end

  RSpec.configure do |config|
    config.extend VCR::RSpec::Macros

    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
    config.treat_symbols_as_metadata_keys_with_true_values = true

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
      @worker = Delayed::Worker.new(quiet: true)
      # Plans
      recreate_default_plans
    end

    config.before(:each) do
      Capybara.default_host = "http://www.sublimevideo.dev"
      Capybara.reset_sessions!
      DatabaseCleaner.start
    end

    # Clear MongoDB Collection
    config.after(:each) do
      DatabaseCleaner.clean
      Delayed::Job.delete_all
    end

    config.after(:all) do
      DatabaseCleaner.clean_with(:truncation) # clean all the databases
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

  # Fix RSpec 2.7 issue https://github.com/guard/guard-rspec/issues/61#issuecomment-2428083
  $rspec_start_time = Time.now

  # Factory need to be required each launch to prevent loading of all models
  require 'factory_girl'
  require Rails.root.join("spec/factories")

  Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

  RSpec.configure do |config|
    # config.include Shoulda::ActionController::Matchers
    config.include Devise::TestHelpers, type: :controller

    # FactoryGirl http://railscasts.com/episodes/158-factories-not-fixtures-revised
    config.include Factory::Syntax::Methods
  end
end

def recreate_default_plans
  Plan.unmemoize_all
  @free_plan      = Factory.create(:free_plan, support_level: 0)
  @paid_plan      = Factory.create(:plan, name: "plus", video_views: 3_000, support_level: 1)
  @sponsored_plan = Factory.create(:sponsored_plan, support_level: 2)
  @custom_plan    = Factory.create(:custom_plan, support_level: 2)
end

# Thanks to Jonas Pfenniger for this!
# http://gist.github.com/487157
# def dev_null(&block)
#   begin
#     orig_stdout = $stdout.dup # does a dup2() internally
#     $stdout.reopen('/dev/null', 'w')
#     yield
#   ensure
#     $stdout.reopen(orig_stdout)
#   end
# end
