MySublimeVideo::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb
  config.middleware.insert_before Rack::Lock, Rack::LiveReload

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  config.action_controller.asset_host = 'http://my.sublimevideo.dev'
  # config.action_controller.asset_host = 'http://my.sublimevideo.192.168.0.19.xip.io'

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method       = :letter_opener
  config.action_mailer.default_url_options   = { host: 'my.sublimevideo.dev' }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Use a different cache store in production
  config.cache_store = :null_store

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # config.log_tags = [:uuid, :remote_ip]

  config.after_initialize do
    Bullet.enable = true
    # Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.growl = false
    # Bullet.xmpp = { :account => 'bullets_account@jabber.org',
    #                 :password => 'bullets_password_for_jabber',
    #                 :receiver => 'your_account@jabber.org',
    #                 :show_online_status => true }
    Bullet.rails_logger = true
  end

end

# Mongoid.logger.level = Logger::DEBUG
# Moped.logger.level = Logger::DEBUG
