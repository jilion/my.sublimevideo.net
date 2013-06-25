source 'https://rubygems.org'
source 'https://8dezqz7z7HWea9vtaFwg@gem.fury.io/me/' # thibaud@jilion.com account

ruby '2.0.0'

gem 'bundler'

gem 'rails', '3.2.13'
gem 'sublime_video_layout', '~> 2.0' # hosted on gemfury
gem 'sublime_video_private_api', '~> 1.0' # hosted on gemfury

# Databases
gem 'pg'
gem 'squeel'
gem 'activerecord-postgres-hstore', github: 'softa/activerecord-postgres-hstore'
gem 'mongoid'

# Views
gem 'haml'
gem 'rabl'
gem 'coffee-rails'
gem 'kaminari'
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
gem 'devise', '~> 2.2.4'
gem 'devise_invitable'
gem 'devise-async'

# API
gem 'oauth'
gem 'oauth-plugin'

# Internals
gem 'dalli'
gem 'cache_digests'
gem 'sidekiq'
gem 'kiqstand' # Mongoid support for Sidekiq

gem 'rescue_me'
gem 'libxml-ruby', require: 'libxml'
gem 'oj'

gem 'state_machine'
gem 'paper_trail'
gem 'uniquify'
gem 'acts-as-taggable-on'
gem 'paranoia'

gem 'responders'
gem 'has_scope'

gem 'fog', '~> 1.12'
gem 'excon'
gem 'carrierwave', require: ['carrierwave', 'carrierwave/processing/mime_types']
gem 'carrierwave-mongoid', require: 'carrierwave/mongoid'
gem 'request-log-analyzer', require: 'request_log_analyzer'
gem 'cocaine'

# CDN
gem 'voxel_hapi', github: 'thibaudgg/voxel_hapi', branch: '1.9.2' # VoxCast CDN
gem 'certified'
gem 'edge_cast'

# until github.com/Shopify/active_merchant/pull/724 is merged
gem 'activemerchant', github: 'rymai/active_merchant', branch: 'ogone-store-amount-option'

gem 'public_suffix', '1.2.0'
gem 'useragent', github: 'jilion/useragent' # needed for stat_request_parser
gem 'stat_request_parser' # hosted on gemfury

gem 'rubyzip', require: 'zip/zip'
gem 'mime-types'
gem 'countries'
gem 'snail'
gem 'PageRankr', require: 'page_rankr'
gem 'twitter'
gem 'array_stats'
gem 'createsend', '~> 2.5' # Campaign Monitor

gem 'honeybadger'
gem 'prowl'
gem 'tinder' # Campfire
gem 'librato-rails', github: 'librato/librato-rails', branch: 'feature/rack_first'
gem 'lograge'
gem 'rack-status'

# Highest version change the query_values method behavior
# https://github.com/sporkmonger/addressable/issues/77
gem 'addressable', '2.2.8', require: 'addressable/uri'

# Stats
gem 'crack'
gem 'pusher', github: 'jilion/pusher-gem'
gem 'redis'

# Tickets
gem 'zendesk_api'

# App
gem 'solve', '0.4.2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'asset_sync'
  gem 'eco'
  gem 'uglifier'
  gem 'execjs'
  gem 'chosen-rails', github: 'jilion/chosen-rails'
  gem 'backbone-rails'
end
gem 'haml_coffee_assets'
gem 'sass-rails'

group :production do
  gem 'rack-google-analytics'
end

group :staging, :production do
  gem 'rack-cache'
  gem 'rack-ssl-enforcer'
  gem 'unicorn'
  gem 'newrelic_rpm'
  gem 'newrelic-redis'
  gem 'newrelic_moped'
end

group :development do
  gem 'rack-livereload'
  gem 'silent-postgres'
  gem 'launchy',        '2.1.0' # after dependency on addressable ~> 2.3
  gem 'letter_opener'
  gem 'em-http-request' # async pusher in populate
  gem 'quiet_assets'
  gem 'bullet'

  gem 'better_errors'
  gem 'binding_of_caller'
  # gem 'i18n-extra_translations', github: 'nicoolas25/i18n-extra_translations', require: false
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'debugger'
  gem 'timecop'

  # Javascript test
  gem 'teabag'
  gem 'guard-teabag'

  # Rails routes view
  gem 'sextant'

  # Guard
  gem 'ruby_gntp', require: false
  gem 'guard-pow', require: false
  gem 'guard-livereload', require: false
  gem 'guard-rspec', require: false
  gem 'guard-shell', require: false
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

