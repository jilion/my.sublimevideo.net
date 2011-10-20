source 'http://rubygems.org'

gem 'rails',                 '3.1.1'

gem 'prototype-rails'
gem 'jquery-rails'
gem 'rails-backbone'

# Databases
gem 'pg',                    '~> 0.11.0'
gem 'squeel',                '~> 0.9.2'

gem 'bson_ext',              '~> 1.4.0'
gem 'mongo',                 '~> 1.4.0'
gem 'mongoid',               '~> 2.2.0'

# Views
gem 'haml',                  '~> 3.1.3'
gem 'coffee-filter',         '~> 0.1.1'
gem 'kaminari',              :git => 'git://github.com/amatsuda/kaminari.git'
gem 'liquid',                '~> 2.2.2'
gem 'RedCloth',              '~> 4.2.7'

# Auth / invitations
gem 'devise',                '~> 1.4.8'
gem 'devise_invitable',      '~> 0.5.5'

# API
gem 'oauth',                 '~> 0.4.5'
gem 'oauth-plugin',          '~> 0.4.0.pre7'
gem 'acts_as_api',           '~> 0.3.10'
# gem 'rack-throttle',         :git => 'git://github.com/rymai/rack-throttle.git', :require => 'rack/throttle'

# Internals
gem 'delayed_job',           '~> 2.1.4'
# gem 'delayed_job',           '~> 3.0.0.pre'
# gem 'delayed_job_active_record'
gem 'rescue_me',             '~> 0.1.0'
gem 'configuration',         '~> 1.3.1'
gem 'libxml-ruby',           '~> 2.2.0', :require => 'libxml'

gem 'state_machine',         '~> 1.0.2'
gem 'paper_trail',           '~> 2.4.0'
gem 'uniquify',              '~> 0.1.0'

gem 'responders',            '~> 0.6.4'
gem 'has_scope',             '~> 0.5.1'

gem 'aws',                   '~> 2.5.6'
gem 'fog',                   '~> 1.0.0'
gem 'carrierwave',           '~> 0.5.7'
gem 'carrierwave-mongoid',   '~> 0.1.1', :require => 'carrierwave/mongoid'
gem 'voxel_hapi',            :git => 'git://github.com/thibaudgg/voxel_hapi.git', :branch => '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '~> 1.11.1', :require => 'request_log_analyzer'

# gem 'activemerchant',        '~> 1.9.1'
# Pull request: https://github.com/Shopify/active_merchant/pull/85
# gem 'activemerchant',        :git => 'git://github.com/ZenCocoon/active_merchant.git' # with the fix for Ogone#parse and more
gem 'activemerchant',        :git => 'git://github.com/rymai/active_merchant.git', :branch => '3ds_from_ZenCocoon'
gem 'public_suffix_service', '~> 0.9.0'
gem 'useragent',             :git => 'git://github.com/Jilion/useragent.git'

gem 'zip',                   '~> 2.0.2', :require => 'zip/zip'
gem 'countries',             '~> 0.6.2'
gem 'PageRankr',             '~> 3.0.1', :require => 'page_rankr'
gem 'twitter',               '~> 1.7.2'
gem 'settingslogic',         '~> 2.0.6'
gem 'array_stats',           '~> 0.6.0'
gem 'createsend',            '~> 1.0.0' # Campaign Monitor

gem 'hoptoad_notifier',      '~> 2.4.11'
gem 'prowl',                 '~> 0.1.3'

gem 'addressable',           '~> 2.2.6'

# Perf
gem 'dalli',                 '~> 1.1.1'

# Stats
gem 'crack',                 '~> 0.1.8'
gem 'pusher',                '~> 0.8.3'

# Javascript test
gem "jasminerice"

group :production do
  gem 'rack-google-analytics', '~> 0.9.2', :require => 'rack/google-analytics'
end

group :production, :staging do
  gem 'rack-ssl-enforcer', '~> 0.2.3'
  gem 'rack-private'
end

group :development, :test do
  gem 'log_buddy'
  gem 'timecop'
  gem 'rspec-rails', '~> 2.7.0'
  # gem 'ruby-debug19'
end

group :development do
  gem 'rails-dev-tweaks', '~> 0.4.0'
  gem 'ffaker'
  gem 'annotate', :git => 'git://github.com/ctran/annotate_models.git'
  gem 'wirble'
  gem 'ruby-graphviz', :require => 'graphviz'
  gem 'heroku'
  gem 'taps'
  gem 'silent-postgres'

  gem 'em-http-request' # async pusher in populate

  gem 'rb-fsevent', '~> 0.9.0.pre3'
  gem 'ruby_gntp'
  gem 'guard', :git => 'git://github.com/guard/guard.git', :branch => 'dev'
  gem 'guard-bundler'
  gem 'guard-pow'
  gem 'guard-livereload'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'guard-coffeescript'
  gem 'guard-jasmine'

  # gem 'rails_mail_preview'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.4'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'eco'
  gem 'uglifier'
end

group :test do
  gem 'spork', '~> 0.9.0.rc9'
  gem 'fuubar'
  gem 'shoulda-matchers', :git => 'git://github.com/thoughtbot/shoulda-matchers.git'
  gem 'capybara'
  gem 'webmock', '~> 1.6.0'
  gem 'typhoeus'
  gem 'vcr',     '~> 1.10.3'

  gem 'database_cleaner'
  gem 'factory_girl_rails', :require => false # loaded in spec_helper Spork.each_run
end
