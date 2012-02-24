# http://ablogaboutcode.com/2012/01/12/a-simple-rails-boot-time-improvement/
source 'https://rubygems.org'
source 'https://gems.gemfury.com/8dezqz7z7HWea9vtaFwg/' # thibaud@jilion.com account

gem 'rails',                 '3.1.3'

gem 'thin'

gem 'prototype-rails'
gem 'jquery-rails',          '~> 1.0.19'
gem 'rails-backbone',        '~> 0.6.0'

# Databases
gem 'pg',                    '~> 0.13.0'
gem 'squeel',                '~> 0.9.5'

gem 'bson_ext',              '~> 1.6.0'
gem 'bson',                  '~> 1.6.0'
gem 'mongo',                 '~> 1.6.0'
gem 'mongoid',               '~> 2.4.5'

# Views
gem 'haml',                  '~> 3.1.3'
gem 'coffee-filter',         '~> 0.1.1'
gem 'kaminari',              '~> 0.13.0'
gem 'liquid',                '~> 2.2.2'
gem 'RedCloth',              '~> 4.2.9'

# Auth / invitations
gem 'devise',                '~> 1.5.1'
gem 'devise_invitable',      '~> 0.6.1' # currently, devise_invitable requires devise ~ 1.4.1...

# API
gem 'oauth',                 '~> 0.4.5'
gem 'oauth-plugin',          '~> 0.4.0.pre7'
gem 'acts_as_api',           '~> 0.3.10'
# gem 'rack-throttle',         git: 'git://github.com/rymai/rack-throttle.git', require: 'rack/throttle'

# Internals
gem 'delayed_job',           '~> 2.1.4'
# gem 'delayed_job',           '~> 3.0.0.pre'
# gem 'delayed_job_active_record'
# gem 'rescue_me',             '~> 0.1.0'
gem 'rescue_me',             '~> 0.1.1', git: 'git://github.com/rymai/rescue_me.git' # until https://github.com/ashirazi/rescue_me/pull/2 is merged
gem 'configuration',         '~> 1.3.1'
gem 'libxml-ruby',           '~> 2.2.0', require: 'libxml'

gem 'state_machine',         '~> 1.1.2'
gem 'paper_trail',           '~> 2.4.0'
gem 'uniquify',              '~> 0.1.0'

gem 'responders',            '~> 0.6.5'
gem 'has_scope',             '~> 0.5.1'

gem 'aws',                   '~> 2.5.6'
gem 'fog',                   '~> 1.1.2'
gem 'carrierwave',           '~> 0.5.7'
gem 'carrierwave-mongoid',   '~> 0.1.1', require: 'carrierwave/mongoid'
gem 'voxel_hapi',            git: 'git://github.com/thibaudgg/voxel_hapi.git', branch: '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '~> 1.12.0', require: 'request_log_analyzer'

# gem 'activemerchant',        '~> 1.9.1'
# Pull request: https://github.com/Shopify/active_merchant/pull/85
# gem 'activemerchant',        git: 'git://github.com/ZenCocoon/active_merchant.git' # with the fix for Ogone#parse and more
gem 'activemerchant',        git: 'git://github.com/rymai/active_merchant.git', branch: '3ds_from_ZenCocoon'
gem 'public_suffix',         '~> 1.0.0'
gem 'useragent',             git: 'git://github.com/jilion/useragent.git' # needed for stat_request_parser
gem 'stat_request_parser',   '~> 1.0.0' # hosted on gemfury

gem 'zip',                   '~> 2.0.2', require: 'zip/zip'
gem 'mime-types'
gem 'countries',             '~> 0.7.0'
gem 'snail',                 '~> 0.5.7'
gem 'PageRankr',             '~> 3.1.0', require: 'page_rankr'
gem 'twitter',               '~> 2.1.0'
gem 'settingslogic',         '2.0.6' # 2.0.7 has ruby-debug19 & jeweler as dependencies => UNACCEPTABLE
gem 'array_stats',           '~> 0.6.0'
gem 'createsend',            '~> 1.0.0' # Campaign Monitor

gem 'airbrake',              '~> 3.0.5'
gem 'prowl',                 '~> 0.1.3'

gem 'addressable',           '~> 2.2.6'

# Perf
gem 'dalli',                 '~> 1.1.3'

# Stats
gem 'crack',                 '~> 0.1.8'
gem 'pusher',                '~> 0.8.3'

# gem 'grafico',               '~> 0.2.5'

# Docs
gem 'coderay',               '~> 1.0.4'
gem 'haml-coderay',          '~> 0.1.2'

# Press
gem "feedzirra", git: "https://github.com/pauldix/feedzirra.git"

gem 'asset_sync'
gem 'rack-no-www'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',         '~> 3.1.5'
  gem 'coffee-rails',       '~> 3.1.1'
  gem 'eco'
  gem 'uglifier'
  gem 'haml_coffee_assets', '0.7.1' # THE 0.8.1 (0.8.0?) WAS CAUSING THE SHIT
  gem 'execjs'
end

group :production do
  # gem 'rack-cache'
  gem 'rack-google-analytics', '~> 0.9.2', require: 'rack/google-analytics'
end

group :staging, :production do
  gem 'rpm_contrib', git: 'git://github.com/titanous/rpm_contrib.git', branch: 'mongoid-instrumentation'
  gem 'newrelic_rpm'
  gem 'rack-ssl-enforcer'
end

group :development, :test do
  gem 'timecop'
  gem 'ffaker'
  gem 'rspec-rails'

  gem 'rack-livereload'
  gem 'rails-dev-tweaks', '~> 0.5.0'

  # Javascript test
  gem 'jasminerice'
end

group :development do
  gem 'annotate', git: 'git://github.com/ctran/annotate_models.git'
  gem 'wirble'
  gem 'heroku'
  gem 'foreman'
  gem 'powder'
  gem 'taps'
  gem 'silent-postgres'
  # gem 'letter_opener'
  gem 'letter_opener', git: 'git://github.com/pcg79/letter_opener.git' # includes a fix not merged yet
  gem 'pry'

  gem 'em-http-request' # async pusher in populate

  gem 'rb-fsevent'

  gem 'ruby_gntp'
  platforms :ruby do
    gem 'rb-readline'
  end
  gem 'guard', git: 'git://github.com/guard/guard.git'

  # gem 'guard-bundler'
  gem 'guard-pow'
  gem 'guard-livereload'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'guard-jasmine'
  # gem 'guard-yard'
end

group :test do
  gem 'spork', '~> 0.9.0'
  gem 'shoulda-matchers'
  gem 'capybara'
  gem 'show_me_the_cookies'
  gem 'webmock',  '~> 1.6.0'
  gem 'typhoeus', '~> 0.2.0'
  gem 'vcr',      '~> 1.10.3'

  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'factory_girl_rails', require: false # loaded in spec_helper Spork.each_run
end
