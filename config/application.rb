require File.expand_path('../boot', __FILE__)

require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'

# If you precompile assets before deploying to production, use this line
Bundler.require *Rails.groups(assets: %w(development test))
# If you want your assets lazily compiled in production, use this line
# Bundler.setup(:default, :assets, Rails.env)

# Required from svl, needed for rake assets:precompile when initialize_on_precompile is false
require 'site_token' unless defined?(SiteToken)

module MySublimeVideo
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.middleware.use Rack::Pjax

    # http://ileitch.github.com/2012/03/24/rails-32-code-reloading-from-lib.html
    config.watchable_dirs['lib'] = [:rb]

    # http://guides.rubyonrails.org/asset_pipeline.html#precompiling-assets
    # For faster asset precompiles, you can partially load your application
    # by setting config.assets.initialize_on_precompile to false
    # in config/application.rb, though in that case templates cannot see
    # application objects or methods. Heroku requires this to be false.
    config.assets.initialize_on_precompile = false

    # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
    config.assets.precompile += %w[admin.js admin.css]
    config.assets.precompile += %w[invoices.css invoices_print.css]
    # Duplicated from svl engine because not loader when initialize_on_precompile is false
    config.assets.precompile += %w[errors.css ie.css]

     # Enable the asset pipeline
     config.assets.enabled = true

     # Version of your assets, change this if you want to expire all your assets
     config.assets.version = '1.0'

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure generators values. Many other options are available, be sure to check the documentation.
    config.app_generators do |g|
      g.orm              :active_record
      g.template_engine  :haml
      g.integration_tool :rspec
      g.test_framework   :rspec, fixture: false, views: false
    end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:protection_key, :password, :cc_]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use sql format for db schema
    config.active_record.schema_format = :sql

    require 'console_methods'
    console do
      Rails::ConsoleMethods.send :include, ConsoleMethods
    end

  end
end
