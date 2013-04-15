# require 'rack/maintenance'

MySublimeVideo::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb
  # config.middleware.insert_before Rack::Cache, Rack::Maintenance, domain: 'sublimevideo.net'
  config.middleware.insert_before Rack::Cache, Rack::SslEnforcer, force_secure_cookies: false
  config.middleware.use Rack::GoogleAnalytics, tracker: 'UA-10280941-8'

  # One-line logs
  config.lograge.enabled = true

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # http://guides.rubyonrails.org/asset_pipeline.html#precompiling-assets
  # For faster asset precompiles, you can partially load your application
  # by setting config.assets.initialize_on_precompile to false
  # in config/application.rb, though in that case templates cannot see
  # application objects or methods. Heroku requires this to be false.
  # config.assets.initialize_on_precompile = false

  # Compress JavaScripts and CSS
  # config.assets.compress = true
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # (comment out if your front-end server doesn't support this)
  # http://devcenter.heroku.com/articles/rails31_heroku_cedar
  config.action_dispatch.x_sendfile_header = nil

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true
  config.action_dispatch.default_url_options = { protocol: 'https' }

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Heroku logs config
  config.action_controller.logger = Logger.new(STDOUT)

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  config.cache_store = :dalli_store
  # https://devcenter.heroku.com/articles/rack-cache-memcached-static-assets-rails31
  config.action_dispatch.rack_cache = {
    metastore:    Dalli::Client.new,
    entitystore:  'file:tmp/cache/rack/body',
    allow_reload: false
  }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  config.action_controller.asset_host = 'https://cdn.sublimevideo.net'

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: 'my.sublimevideo.net', protocol: 'https' }

  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'smtp.sendgrid.net',
    port: '587',
    authentication: :plain,
    user_name: ENV['SENDGRID_USERNAME'],
    password: ENV['SENDGRID_PASSWORD'],
    domain: ENV['SENDGRID_DOMAIN']
  }

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Use Dalli as the rack-cache metastore
  # $cache = Dalli::Client.new
  # config.middleware.use ::Rack::Cache, metastore: $cache, entitystore: 'file:tmp/cache/entity'
end
