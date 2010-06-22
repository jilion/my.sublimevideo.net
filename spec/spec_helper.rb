require 'rubygems'
require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However, 
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  
  # This file is copied to ~/spec when you run 'ruby script/generate rspec'
  # from the project root directory.
  ENV["RAILS_ENV"] ||= 'test'
  require File.dirname(__FILE__) + "/../config/environment" unless defined?(Rails)
  require 'rspec/rails'
end

Spork.each_run do
  # This code will be run each time you run your specs.
  
  # Requires supporting files with custom matchers and macros, etc, in ./support/ and its subdirectories.
  Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }
    
  Rspec.configure do |config|
    # == Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.mock_with :rspec
    
    config.fixture_path = "#{::Rails.root}/spec/fixtures"
    
    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, comment the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true
    
    config.before(:all) do
      unless File.exist?('public/uploads/cloudfront/')
        Dir.mkdir('public/uploads/cloudfront/')
        Dir.mkdir('public/uploads/cloudfront/sublimevideo.videos/')
        Dir.mkdir('public/uploads/cloudfront/sublimevideo.videos/download/')
      end
      unless File.exist?('public/uploads/cloudfront/sublimevideo.videos/download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz')
        FileUtils.cp(
          Rails.root.join('spec/fixtures/logs/cloudfront_download/E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz'),
          Rails.root.join('public/uploads/cloudfront/sublimevideo.videos/download/')
        )
      end
    end
  end
  
  VCR.config do |c|
    c.cassette_library_dir     = 'spec/fixtures/vcr_cassettes'
    c.http_stubbing_library    = :fakeweb # or :webmock
    c.default_cassette_options = { :record => :new_episodes }
  end
  
end