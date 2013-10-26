source 'https://rubygems.org'
source 'https://8dezqz7z7HWea9vtaFwg:@gem.fury.io/me/' # thibaud@jilion.com account

ruby '2.0.0'

gem 'rails', '~> 4.0.0'
gem 'sprockets-rails', github: 'rails/sprockets-rails'

gem 'sublime_video_layout', '~> 2.6' # hosted on gemfury
gem 'sublime_video_private_api', '~> 1.5' # hosted on gemfury

# Databases
gem 'pg'
gem 'mongoid', github: 'mongoid'

# Views
gem 'haml'
gem 'rabl'
gem 'coffee-rails'
gem 'kaminari', github: 'kolodovskyy/kaminari' # https://github.com/amatsuda/kaminari/pull/433
gem 'liquid'
gem 'hpricot'
gem 'display_case'
gem 'rails_autolink'
# until https://github.com/fphilipe/premailer-rails/pull/83 is merged
gem 'premailer-rails', github: 'jilion/premailer-rails', branch: 'fix-82'
gem 'turbolinks'
gem 'google-analytics-turbolinks'

# Admin charts
gem 'groupdate'
gem 'chartkick'

# Auth / invitations
gem 'devise', '~> 3.0.0'
gem 'devise_invitable'
gem 'devise-async'

# API
gem 'oauth'
gem 'oauth-plugin', github: 'pelle/oauth-plugin' # Rails 4 support

# Internals
gem 'sidekiq'

gem 'rescue_me'
gem 'libxml-ruby', require: 'libxml'
gem 'oj'

gem 'state_machine'
gem 'paper_trail', '3.0.0.beta1'
gem 'uniquify'
gem 'acts-as-taggable-on', github: 'mbleigh/acts-as-taggable-on' # Need > 2.4.1
gem 'paranoia'

gem 'responders'
gem 'has_scope'

gem 'fog', github: 'fog/fog' # Need > 1.16.0
gem 'carrierwave', require: ['carrierwave', 'carrierwave/processing/mime_types']
gem 'carrierwave-mongoid', require: 'carrierwave/mongoid'
gem 'request-log-analyzer', require: 'request_log_analyzer'
gem 'cocaine'

# CDN
gem 'voxel_hapi', github: 'thibaudgg/voxel_hapi', branch: '1.9.2' # VoxCast CDN
gem 'edge_cast'

gem 'activemerchant'

gem 'public_suffix'
gem 'useragent', github: 'jilion/useragent' # needed for stat_request_parser
gem 'stat_request_parser' # hosted on gemfury

gem 'rubyzip'
gem 'mime-types'
gem 'countries'
gem 'country_select'
gem 'snail'
gem 'PageRankr'
gem 'twitter'
gem 'array_stats'
gem 'createsend' # Campaign Monitor
gem 'http_content_type'

gem 'honeybadger'
gem 'prowl'
gem 'tinder' # Campfire
gem 'librato-rails'
gem 'rack-status'

# Highest version change the query_values method behavior
# https://github.com/sporkmonger/addressable/issues/77
gem 'addressable', '~> 2.2.8', require: 'addressable/uri'

# Stats
gem 'crack'
gem 'pusher'
gem 'redis'

# Tickets
gem 'zendesk_api'

# App
gem 'solve'

# Gems used only for assets and not required
# in production environments by default.
gem 'uglifier'
gem 'execjs'
gem 'backbone-rails'
gem 'haml_coffee_assets'
gem 'sass-rails'

gem 'chosen-rails', github: 'jilion/chosen-rails'
gem 'compass-rails', github: 'Compass/compass-rails'

group :production do
  gem 'rack-google-analytics', '~> 0.11.0'
end

group :staging, :production do
  gem 'lograge'
  gem 'rack-cache'
  gem 'rack-ssl-enforcer'
  gem 'unicorn', require: false
  gem 'newrelic_rpm'
  gem 'newrelic-redis'
  gem 'newrelic_moped'
  gem 'asset_sync'
  gem 'memcachier'
  gem 'dalli'
  gem 'rails_12factor'
end

group :development do
  gem 'rack-livereload'
  gem 'launchy'
  gem 'quiet_assets'
  gem 'bullet'
  gem 'annotate'

  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'i18n-extra_translations', require: false

  # gem 'em-http-request' # async pusher in populate
  gem 'letter_opener'
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'timecop'

  # Javascript test
  gem 'teaspoon'

  # Rails routes view
  gem 'sextant'

  # Guard
  gem 'ruby_gntp', require: false
  gem 'guard-pow', require: false
  gem 'guard-livereload', require: false
  gem 'guard-rspec', require: false
  gem 'guard-shell', require: false
  gem 'guard-teaspoon', require: false
end

group :test do
  gem 'shoulda-matchers'
  gem 'ffaker'
  gem 'capybara'
  gem 'capybara-email'
  gem 'poltergeist'
  gem 'show_me_the_cookies'
  gem 'webmock',             '~> 1.6.0'
  gem 'typhoeus',            '~> 0.2.0'
  gem 'vcr',                 '~> 1.10.3'
  gem 'codeclimate-test-reporter', require: false

  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'factory_girl_rails' # loaded in spec_helper Spork.each_run
end
