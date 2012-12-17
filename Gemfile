source 'https://rubygems.org'
source 'https://gems.gemfury.com/8dezqz7z7HWea9vtaFwg' # thibaud@jilion.com account

ruby '1.9.3'

gem 'bundler'

gem 'rails', '3.2.9'

gem 'sublime_video_layout', '~> 2.0' # hosted on gemfury

# Databases
gem 'pg'
gem 'squeel'
gem 'activerecord-postgres-hstore', github: 'softa/activerecord-postgres-hstore'
gem 'mongoid'

# Views
gem 'haml'
gem 'coffee-rails'
gem 'coffee-filter'
gem 'kaminari'
gem 'liquid'
gem 'display_case'
gem 'rails_autolink'
gem 'hpricot'
gem 'premailer', github: 'jilion/premailer'
gem 'premailer-rails3'

# Auth / invitations
gem 'devise'
gem 'devise_invitable'
gem 'devise-async'

# API
gem 'oauth'
gem 'oauth-plugin'
gem 'acts_as_api'

# Internals
gem 'sidekiq'
gem 'sinatra', require: false # needed for Sidekiq Web UI
gem 'slim' # needed for Sidekiq Web UI
gem 'kiqstand' # Mongoid support for Sidekiq

gem 'rescue_me'
gem 'configuration'
gem 'libxml-ruby', require: 'libxml'
gem 'yajl-ruby', require: 'yajl' # json

gem 'state_machine'
gem 'paper_trail'
gem 'uniquify'
gem 'acts-as-taggable-on'
gem 'paranoia'

gem 'responders'
gem 'has_scope'

gem 'aws'
gem 'fog'
gem 's3etag'
gem 'carrierwave', require: ['carrierwave', 'carrierwave/processing/mime_types']
gem 'carrierwave-mongoid', require: 'carrierwave/mongoid'
gem 'request-log-analyzer', require: 'request_log_analyzer'
gem 'cocaine'

gem 'rack-pjax'

# CDN
gem 'voxel_hapi', github: 'thibaudgg/voxel_hapi', branch: '1.9.2' # VoxCast CDN
gem 'edge_cast'

gem 'activemerchant'
gem 'public_suffix'
gem 'useragent', github: 'jilion/useragent' # needed for stat_request_parser
gem 'stat_request_parser' # hosted on gemfury

gem 'rubyzip', require: 'zip/zip'
gem 'mime-types'
gem 'countries'
gem 'snail'
gem 'PageRankr', require: 'page_rankr'
gem 'twitter'
gem 'array_stats'
gem 'createsend' # Campaign Monitor

gem 'airbrake'
gem 'prowl'
gem 'tinder' # Campfire
gem 'librato-rails'
gem 'lograge'

# Highest version change the query_values method behavior
# https://github.com/sporkmonger/addressable/issues/77
gem 'addressable', '2.2.8', require: 'addressable/uri'

# Stats
gem 'crack'
gem 'pusher'
gem 'redis'

# Tickets
gem 'zendesk_api'
gem 'highrise'

# App
gem 'solve'

# Videos
gem 'vimeo'
gem 'youtube_it'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'asset_sync'
  gem 'eco'
  gem 'uglifier'
  gem 'haml_coffee_assets'
  gem 'execjs'
  gem 'chosen-rails', github: 'jilion/chosen-rails'

  gem 'rails-backbone', '~> 0.6.0'
end
gem 'sass-rails'

group :production do
  gem 'rack-google-analytics'
end

group :staging, :production do
  gem 'rack-cache'
  gem 'rack-ssl-enforcer'
  gem 'thin'
  gem 'dalli'
  gem 'newrelic_rpm'
  gem 'newrelic-redis'
  gem 'newrelic_moped'
end

group :development do
  gem 'rack-livereload'
  gem 'silent-postgres'
  gem 'letter_opener', github: 'ryanb/letter_opener' # includes a fix not released yet
  gem 'em-http-request' # async pusher in populate
  gem 'quiet_assets'
end

group :development, :test do
  gem 'rspec-rails', github: 'rspec/rspec-rails'
  gem 'debugger'
  gem 'timecop'
  gem 'better_errors'
  gem 'binding_of_caller'

  # Javascript test
  gem 'jasminerice'
  # Rails routes view
  gem 'sextant'
end

group :test do
  gem 'ffaker'
  gem 'shoulda-matchers'
  gem 'capybara'
  gem 'capybara-email'
  gem 'poltergeist'
  gem 'show_me_the_cookies'
  gem 'rspec-core', github: 'rspec/rspec-core'
  gem 'webmock', '~> 1.6.0'
  gem 'typhoeus', '~> 0.2.0'
  gem 'vcr', '~> 1.10.3'

  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'factory_girl_rails' # loaded in spec_helper Spork.each_run
end

group :tools do
  gem 'annotate'
  gem 'wirble'
  gem 'powder'
  gem 'brakeman'

  # Guard
  gem 'ruby_gntp'
  gem 'rb-fsevent'
  gem 'rb-readline'

  gem 'pry'
  gem 'guard'
  gem 'guard-pow'
  gem 'guard-livereload'
  gem 'guard-rspec'
  gem 'guard-jasmine'
  gem 'guard-shell'
end
