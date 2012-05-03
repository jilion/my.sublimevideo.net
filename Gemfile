# http://ablogaboutcode.com/2012/01/12/a-simple-rails-boot-time-improvement/
source 'https://rubygems.org'
source 'https://gems.gemfury.com/8dezqz7z7HWea9vtaFwg/' # thibaud@jilion.com account

gem 'rails',                 '3.2.3'
gem 'sublimevideo_layout',   git: 'git@github.com:jilion/sublimevideo_layout.git', branch: 'crm_improvements'

# Javascript Assets
gem 'prototype-rails',       '~> 3.2.1'
gem 'rails-backbone',        '~> 0.6.0'

# Databases
gem 'pg',                    '~> 0.13.0'
gem 'squeel',                '~> 1.0.0'

gem 'bson_ext',              '~> 1.6.0'
gem 'bson',                  '~> 1.6.0'
gem 'mongo',                 '~> 1.6.0'
gem 'mongoid',               '~> 2.4.7'

# Views
gem 'haml',                  '~> 3.1.3'
gem 'coffee-filter',         '~> 0.1.1'
gem 'kaminari',              '~> 0.13.0'
gem 'liquid',                '~> 2.2.2'
gem 'rails_autolink',        '~> 1.0.7'

# Auth / invitations
gem 'devise',                '~> 2.0.1'
gem 'devise_invitable',      '~> 1.0.0'

# API
gem 'oauth',                 '~> 0.4.5'
gem 'oauth-plugin',          '~> 0.4.0.pre7'
gem 'acts_as_api',           '~> 0.3.10'
# gem 'rack-throttle',         git: 'git://github.com/rymai/rack-throttle.git', require: 'rack/throttle'

# Internals
gem 'delayed_job',           github: 'collectiveidea/delayed_job', branch: 'v2.1'
gem 'rescue_me',             github: 'rymai/rescue_me' # until https://github.com/ashirazi/rescue_me/pull/2 is merged
gem 'configuration',         '~> 1.3.1'
gem 'libxml-ruby',           '~> 2.2.0', require: 'libxml'

gem 'state_machine',         '~> 1.1.2'
gem 'paper_trail',           '~> 2.6.0'
gem 'uniquify',              '~> 0.1.0'
gem 'acts-as-taggable-on',   '~> 2.2.2'

gem 'responders',            '~> 0.7.0'
gem 'has_scope',             '~> 0.5.1'

gem 'aws',                   '~> 2.5.6'
gem 'fog',                   '~> 1.3.1'
gem 'carrierwave',           '~> 0.6.2'
gem 'carrierwave-mongoid',   '~> 0.1.1', require: 'carrierwave/mongoid'
gem 'voxel_hapi',            github: 'thibaudgg/voxel_hapi', branch: '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '~> 1.12.0', require: 'request_log_analyzer'

gem 'activemerchant',        github: 'rymai/active_merchant', branch: '3ds_from_ZenCocoon'
gem 'public_suffix',         '~> 1.0.0'
gem 'useragent',             github: 'jilion/useragent' # needed for stat_request_parser
gem 'stat_request_parser',   '~> 1.1.0' # hosted on gemfury

gem 'rubyzip',               '~> 0.9.7', require: 'zip/zip'
gem 'mime-types'
gem 'countries',             '~> 0.8.2'
gem 'snail',                 '~> 0.5.7'
gem 'PageRankr',             '~> 3.1.0', require: 'page_rankr'
gem 'twitter',               '~> 2.1.0'
gem 'settingslogic',         '2.0.6' # 2.0.7 has ruby-debug19 & jeweler as dependencies => UNACCEPTABLE
gem 'array_stats',           '~> 0.6.0'
gem 'createsend',            '~> 1.0.0' # Campaign Monitor

gem 'airbrake',              '~> 3.0.5'
gem 'prowl',                 '~> 0.1.3'

gem 'addressable',           '~> 2.2.6', require: 'addressable/uri'

# Stats
gem 'crack',                 '~> 0.1.8'
gem 'pusher',                '~> 0.9.2'
gem 'redis',                 '~> 2.2.2'

# Tickets
gem 'zendesk_client',        github: 'jilion/zendesk_client'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'asset_sync'
  gem 'sass-rails',   '~> 3.2.0'
  gem 'coffee-rails', '~> 3.2.0'
  gem 'eco'
  gem 'uglifier'
  gem 'haml_coffee_assets', '~> 0.8.2'
  gem 'execjs'
end

group :production do
  gem 'rack-google-analytics', '~> 0.9.2', require: 'rack/google-analytics'
end

group :staging, :production do
  gem 'rack-ssl-enforcer'
  gem 'thin'
  gem 'dalli', '~> 2.0.0'
  gem 'rpm_contrib'
  gem 'newrelic_rpm'
end

group :development do
  gem 'rack-livereload'
  gem 'silent-postgres'
  gem 'letter_opener', github: 'pcg79/letter_opener' # includes a fix not merged yet
  gem 'em-http-request' # async pusher in populate
  gem 'quiet_assets'
end

group :development, :test do
  gem 'rspec-core', github: 'rspec/rspec-core'
  gem 'rspec-rails'
  gem 'debugger'

  # Javascript test
  gem 'jasminerice'
end

group :test do
  gem 'timecop'
  gem 'ffaker'
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

group :tools do
  gem 'annotate', github: 'ctran/annotate_models'
  gem 'wirble'
  gem 'heroku'
  gem 'foreman'
  gem 'powder'
  gem 'pry'

  # Guard
  gem 'growl'
  # platforms :ruby do
  #   gem 'rb-readline'
  # end

  gem 'guard', github: 'guard/guard', branch: 'listen'
  gem 'guard-pow'
  gem 'guard-livereload'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'guard-jasmine'
  # gem 'guard-yard'
end
