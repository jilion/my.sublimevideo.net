# http://ablogaboutcode.com/2012/01/12/a-simple-rails-boot-time-improvement/
source 'https://rubygems.org'
source 'https://gems.gemfury.com/8dezqz7z7HWea9vtaFwg' # thibaud@jilion.com account

ruby '1.9.3'

gem 'bundler'

gem 'rails', github: 'rails/rails', branch: '3-2-stable'

gem 'sublimevideo_layout', '1.4.2' # hosted on gemfury

# Databases
gem 'pg'
gem 'squeel'
gem 'activerecord-postgres-hstore', github: 'softa/activerecord-postgres-hstore'
gem 'moped',                 github: 'mongoid/moped'
gem 'mongoid'
gem 'kiqstand'

# Views
gem 'haml',                  '~> 3.1.6'
gem 'coffee-rails',          '~> 3.2.2'
gem 'coffee-filter',         '~> 0.1.1'
gem 'kaminari',              '~> 0.14.0'
gem 'liquid',                '~> 2.4.1'
gem 'display_case',          '~> 0.0.4'
gem 'rails_autolink',        '~> 1.0.7'
gem 'hpricot',               '~> 0.8.6'
gem 'premailer',             github: 'jilion/premailer'
gem 'premailer-rails3',      '~> 1.3.1'

# Auth / invitations
gem 'devise'
gem 'devise_invitable'
gem 'devise-async'

# API
gem 'oauth',                 '~> 0.4.7'
gem 'oauth-plugin',          '~> 0.4.1'
gem 'acts_as_api',           '~> 0.4.1'

# Internals
gem 'sidekiq', github: 'mperham/sidekiq'
gem 'sinatra', require: false
gem 'slim'

gem 'rescue_me',             github: 'rymai/rescue_me' # until https://github.com/ashirazi/rescue_me/pull/2 is merged
gem 'configuration',         '~> 1.3.1'
gem 'libxml-ruby',           '~> 2.2.0', require: 'libxml'

gem 'state_machine',         '~> 1.1.2'
gem 'paper_trail',           '~> 2.6.0'
gem 'uniquify',              '~> 0.1.0'
gem 'acts-as-taggable-on',   '~> 2.3.3'

gem 'responders',            '~> 0.9.2'
gem 'has_scope',             '~> 0.5.1'

gem 'aws',                   '~> 2.5.6'
gem 'fog'
gem 's3etag'
gem 'carrierwave',           '~> 0.6.2', require: ['carrierwave', 'carrierwave/processing/mime_types']
# gem 'carrierwave-mongoid',   '~> 0.2.1', require: 'carrierwave/mongoid'
gem 'carrierwave-mongoid',   github: 'jnicklas/carrierwave-mongoid', branch: 'mongoid-3.0', require: 'carrierwave/mongoid'
gem 'request-log-analyzer',  '~> 1.12.0', require: 'request_log_analyzer'
gem 'cocaine',               '~> 0.4.2'

gem 'rack-pjax'

# CDN
gem 'voxel_hapi',            github: 'thibaudgg/voxel_hapi', branch: '1.9.2' # VoxCast CDN
gem 'edge_cast',             '~> 0.0.1' # hosted on gemfury

gem 'activemerchant',        '1.28.0'
gem 'public_suffix',         '~> 1.1.2'
gem 'useragent',             github: 'jilion/useragent' # needed for stat_request_parser
gem 'stat_request_parser',   '~> 1.1.0' # hosted on gemfury

gem 'rubyzip',               '~> 0.9.7', require: 'zip/zip'
gem 'mime-types'
gem 'countries',             '~> 0.8.2'
gem 'snail',                 '~> 0.6.1'
gem 'PageRankr',             '~> 3.2.1', require: 'page_rankr'
gem 'twitter',               '~> 3.7.0'
gem 'array_stats',           '~> 0.6.0'
gem 'createsend',            '~> 1.0.0' # Campaign Monitor

gem 'airbrake',              '~> 3.1.2'
gem 'prowl',                 '~> 0.1.3'

# Highest version change the query_values method behavior
# https://github.com/sporkmonger/addressable/issues/77
gem 'addressable',           '2.2.8', require: 'addressable/uri'

# Stats
gem 'crack',                 '~> 0.1.8'
gem 'pusher',                '~> 0.9.2'
gem 'redis',                 '~> 3.0.1'

# Tickets
gem 'zendesk_api',           '~> 0.1.2'

# App
gem 'solve'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'asset_sync'
  gem 'eco'
  gem 'uglifier'
  gem 'haml_coffee_assets',   '~> 1.4.6'
  gem 'execjs'
  gem 'chosen-rails', github: 'jilion/chosen-rails'

  # gem 'prototype-rails',       '~> 3.2.1'
  gem 'rails-backbone',        '~> 0.6.0'
end
gem 'sass-rails', '~> 3.2.5'

group :production do
  gem 'rack-google-analytics', '~> 0.11'
end

group :staging, :production do
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
  gem 'rspec-rails', '~> 2.11.0'
  gem 'debugger'
  gem 'timecop'

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
  gem "capybara-webkit"
  gem 'show_me_the_cookies'
  gem 'webmock',  '~> 1.6.0'
  gem 'typhoeus', '~> 0.2.0'
  gem 'vcr',      '~> 1.10.3'

  gem 'database_cleaner', '~> 0.8.0'
  gem 'factory_girl'
  gem 'factory_girl_rails' # loaded in spec_helper Spork.each_run
end

group :tools do
  gem 'annotate'
  gem 'wirble'
  gem 'heroku'
  gem 'foreman'
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
  # gem 'guard-yard'
end
