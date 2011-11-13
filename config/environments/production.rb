MySublimeVideo::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb
  
  # SVS
  # config.middleware.insert_before(Rack::Lock, Rack::NoWWW)
  config.middleware.use(Rack::SslEnforcer, :except => /^\/r\// )
  config.middleware.use(Rack::GoogleAnalytics, :tracker => 'UA-10280941-8')
  # require 'rack/throttle/custom_hourly'
  # config.middleware.use(Rack::Throttle::Hourly, :max => 3600, :cache => Rails.cache, :key_prefix => :throttle)

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Specifies the header that your server uses for sending files
  # (comment out if your front-end server doesn't support this)
  # http://devcenter.heroku.com/articles/rails31_heroku_cedar
  config.action_dispatch.x_sendfile_header = nil

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Heroku logs config
  config.action_controller.logger = Logger.new(STDOUT)

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  config.cache_store = :dalli_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { :host => 'my.sublimevideo.net' }

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
end