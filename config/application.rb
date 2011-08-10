require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the default gems, the ones in the
# current environment and also include :assets gems if in development
# or test environments.
Bundler.require *Rails.groups(:assets) if defined?(Bundler)

module MySublimeVideo
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    require 'oauth/rack/oauth_filter'
    config.middleware.use OAuth::Rack::OAuthFilter
    
    # Add additional load paths for your own custom dirs
    config.autoload_paths += %W[#{config.root}/lib]
    Dir["#{config.root}/lib/{log_file_format,responders,validators}/**/*.rb"].each do |f|
      dir = File.expand_path(File.dirname(f))
      config.autoload_paths += [dir] if config.autoload_paths.exclude?(dir)
    end

    # Activate observers that should always be running
    # config.active_record.observers = :site_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure generators values. Many other options are available, be sure to check the documentation.
    config.generators do |g|
      g.orm                 :active_record
      g.template_engine     :haml
      g.integration_tool    :rspec
      g.test_framework      :rspec, :fixture => false, :views => false
      # g.fixture_replacement :factory_girl, :dir => "spec/factories"
    end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:protection_key, :password, :cc]
  end
end
