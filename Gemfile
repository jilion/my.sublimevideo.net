source 'https://rubygems.org'
source 'https://8dezqz7z7HWea9vtaFwg@gem.fury.io/me/' # thibaud@jilion.com account

ruby '1.9.3'

gem 'bundler'

gem 'rails', '3.2.12' # until 3.2.14 is out!
gem 'sublime_video_layout', '~> 2.0' # hosted on gemfury
gem 'sublime_video_private_api', '~> 1.0' # hosted on gemfury

# Databases
gem 'pg'
gem 'squeel'
gem 'activerecord-postgres-hstore', github: 'softa/activerecord-postgres-hstore'
gem 'mongoid'

# Views
gem 'haml'
gem 'coffee-rails'
gem 'kaminari'
gem 'liquid'
gem 'hpricot'
gem 'display_case'
gem 'rails_autolink'
gem 'premailer', github: 'jilion/premailer'
gem 'premailer-rails'
gem 'turbolinks', github: 'jilion/turbolinks', branch: 'ios_video_issue'
gem 'google-analytics-turbolinks'

# Auth / invitations
gem 'devise', '~> 2.1.2'
gem 'devise_invitable'
gem 'devise-async'

# API
gem 'oauth'
gem 'oauth-plugin'
gem 'acts_as_api'

# Internals
gem 'dalli'
gem 'sidekiq'
gem 'kiqstand' # Mongoid support for Sidekiq

gem 'rescue_me'
gem 'configurator', github: 'jilion/configurator'
gem 'libxml-ruby', require: 'libxml'
gem 'yajl-ruby', require: 'yajl' # json

gem 'state_machine'
gem 'paper_trail'
gem 'uniquify'
gem 'acts-as-taggable-on'
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

gem 'activemerchant'
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

gem 'airbrake'
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
gem 'solve'

# Update was needed, but not directly used by mysv
gem 'json'
gem 'net-scp', '1.0.4'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'asset_sync'
  gem 'eco'
  gem 'uglifier'
  gem 'haml_coffee_assets'
  gem 'execjs'
  gem 'chosen-rails', github: 'jilion/chosen-rails'
  gem 'backbone-rails'
end
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
  gem 'rspec-rails'
  gem 'debugger'
  gem 'timecop'

  # Javascript test
  gem 'jasminerice'
  gem 'guard-jasmine'
  # Rails routes view
  gem 'sextant'
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

group :tools do
  gem 'annotate'
  gem 'wirble'
  gem 'powder'

  # Guard
  gem 'ruby_gntp'
  gem 'rb-fsevent'

  gem 'guard-pow'
  gem 'guard-livereload'
  gem 'guard-rspec'
  gem 'guard-shell'
end
