MySublimeVideo::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb
  config.middleware.insert_before Rack::Cache, Rack::Auth::Basic, "Staging" do |u, p|
    [u, p] == ['jilion', ENV['PRIVATE_CODE']]
  end
  config.middleware.insert_before Rack::Cache, Rack::SslEnforcer, force_secure_cookies: false

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

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

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
  config.action_controller.asset_host = '//cdn.sublimevideo.net'

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: 'my.sublimevideo-staging.net', protocol: 'https' }

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
end
