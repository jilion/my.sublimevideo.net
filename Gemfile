source 'https://rubygems.org'
source 'https://8dezqz7z7HWea9vtaFwg:@gem.fury.io/me/' # thibaud@jilion.com account

ruby '2.0.0'

gem 'rails', '4.0.0'

# until https://github.com/rails/sprockets-rails/pull/77 is merged
gem 'sprockets-rails', github: 'johnmcdowall/sprockets-rails'

gem 'sublime_video_layout', '~> 2.0' # hosted on gemfury
gem 'sublime_video_private_api', '~> 1.5' # hosted on gemfury

# Old stuff from Rails 3
gem 'protected_attributes' # TODO migrate to strong_parameters

# Databases
gem 'pg'
gem 'mongoid', github: 'mongoid/mongoid' # Rails 4 support

# Views
gem 'haml'
gem 'rabl'
gem 'coffee-rails'
gem 'kaminari', github: 'kolodovskyy/kaminari' # https://github.com/amatsuda/kaminari/pull/433
gem 'liquid'
gem 'hpricot'
gem 'display_case'
gem 'rails_autolink'
gem 'regru-premailer'
gem 'premailer-rails', github: 'jilion/premailer-rails', branch: 'regru-premailer-dependency'
gem 'turbolinks', github: 'jilion/turbolinks', branch: 'ios_video_issue'
gem 'google-analytics-turbolinks'

# Admin charts
gem 'groupdate'
gem 'chartkick'

# Auth / invitations
gem 'devise', '~> 3.0.0'
# Until 1.1.9
gem 'devise_invitable', github: 'scambra/devise_invitable'
gem 'devise-async'

# API
gem 'oauth'
gem 'oauth-plugin', github: 'tomhughes/oauth-plugin', branch: 'rails4' # Rails 4 support

# Internals
gem 'cache_digests'
gem 'sidekiq'
gem 'kiqstand', github: 'mongoid/kiqstand' # Mongoid support for Sidekiq

gem 'rescue_me'
gem 'libxml-ruby', require: 'libxml'
gem 'yajl-ruby', require: 'yajl' # json

gem 'state_machine'
gem 'paper_trail', github: 'airblade/paper_trail' # Rails 4 support
gem 'uniquify'
gem 'acts-as-taggable-on', github: 'mbleigh/acts-as-taggable-on' # Need > 2.4.1
gem 'paranoia'

gem 'responders'
gem 'has_scope'

gem 'fog'
gem 'excon'
gem 'carrierwave', require: ['carrierwave', 'carrierwave/processing/mime_types']
gem 'carrierwave-mongoid', require: 'carrierwave/mongoid'
gem 'request-log-analyzer', require: 'request_log_analyzer'
gem 'cocaine'

# CDN
gem 'voxel_hapi', github: 'thibaudgg/voxel_hapi', branch: '1.9.2' # VoxCast CDN
gem 'edge_cast'

# until github.com/Shopify/active_merchant/pull/724 is merged
gem 'activemerchant', github: 'rymai/active_merchant', branch: 'ogone-store-amount-option'

gem 'public_suffix'
gem 'useragent', github: 'jilion/useragent' # needed for stat_request_parser
gem 'stat_request_parser' # hosted on gemfury

gem 'rubyzip', require: 'zip/zip'
gem 'mime-types'
gem 'countries'
gem 'country_select'
gem 'snail'
gem 'PageRankr', require: 'page_rankr'
gem 'twitter'
gem 'array_stats'
gem 'createsend' # Campaign Monitor

gem 'honeybadger'
gem 'prowl'
gem 'tinder' # Campfire
# gem 'librato-rails', github: 'librato/librato-rails'
gem 'librato-rails', github: 'librato/librato-rails', branch: 'feature/rack_first'
gem 'rack-status'

# Highest version change the query_values method behavior
# https://github.com/sporkmonger/addressable/issues/77
gem 'addressable', '~> 2.2.8', require: 'addressable/uri'
# gem 'addressabler'

# Stats
gem 'crack'
gem 'pusher', github: 'jilion/pusher-gem'
gem 'redis'

# Tickets
gem 'zendesk_api'

# App
gem 'solve'

# Gems used only for assets and not required
# in production environments by default.
# gem 'eco'
gem 'uglifier'
gem 'execjs'
gem 'backbone-rails'
gem 'haml_coffee_assets'
gem 'sass-rails'

gem 'chosen-rails', github: 'jilion/chosen-rails'
gem 'compass-rails', github: 'milgner/compass-rails', branch: 'rails4'

group :production do
  gem 'rack-google-analytics'
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
end

group :development do
  gem 'rack-livereload'
  gem 'silent-postgres'
  gem 'launchy'
  gem 'quiet_assets'
  gem 'bullet'

  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'i18n-extra_translations', github: 'nicoolas25/i18n-extra_translations', require: false

  # gem 'em-http-request' # async pusher in populate
  # gem 'letter_opener'
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

  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'factory_girl_rails' # loaded in spec_helper Spork.each_run
end

