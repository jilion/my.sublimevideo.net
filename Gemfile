source "http://rubygems.org"

gem 'rake',                  '0.8.7'

gem 'rails',                 '3.0.10'

# Databases
gem 'pg',                    '0.11.0'
gem 'meta_where',            '1.0.4'

gem 'bson_ext',              '~> 1.3.0'
gem 'bson',                  '~> 1.3.0'
gem 'mongo',                 '~> 1.3.0'
gem 'mongoid',               '~> 2.2.0'

# Views
gem 'haml',                  '3.1.2'
gem 'kaminari',              '0.12.4'
gem 'jammit',                '0.6.3'
gem 'liquid',                '2.2.2'
gem 'RedCloth',              '4.2.8'

# Auth / invitations
gem 'devise',                '1.4.2'
gem 'devise_invitable',      '0.5.4'

# API
gem 'oauth',                 '0.4.5'
gem 'oauth-plugin',          '0.4.0.pre7'
gem 'acts_as_api',           '0.3.6'
# gem 'rack-throttle',         :git => 'git://github.com/rymai/rack-throttle.git', :require => 'rack/throttle'

# Internals
gem 'delayed_job',           '2.1.4'
gem 'rescue_me',             '0.1.0'
gem 'configuration',         '1.2.0'
gem 'libxml-ruby',           '2.2.0', :require => 'libxml'

gem 'state_machine',         '0.10.4'
gem 'paper_trail',           '2.2.9'
gem 'uniquify',              '0.1.0'

gem 'responders',            '0.6.2'
gem 'has_scope',             '0.5.1'

gem 'aws',                   '2.5.6'
gem 'fog',                   '0.10.0'
# gem 'carrierwave',           '0.5.6'
# For mongoid 2.1.x support, Until my patch is merged or mongoid support is extracted from carrierwave
# BUT since mongoid 2.1.x break so many specs, it's currently useless
gem 'carrierwave',           :git => 'git://github.com/rymai/carrierwave.git'
gem 'voxel_hapi',            :git => 'git://github.com/thibaudgg/voxel_hapi.git', :branch => '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '1.11.0', :require => 'request_log_analyzer'

# gem 'activemerchant',        '~> 1.9.1'
# Pull request: https://github.com/Shopify/active_merchant/pull/85
# gem 'activemerchant',        :git => 'git://github.com/ZenCocoon/active_merchant.git' # with the fix for Ogone#parse and more
gem 'activemerchant',        :git => 'git://github.com/rymai/active_merchant.git', :branch => '3ds_from_ZenCocoon', :ref => '2f35b9f1c685b25d3f06f092684c2c7b581d4a9d'
gem 'public_suffix_service', '0.8.1'
gem 'useragent',             :git => 'git://github.com/jilion/useragent.git'

gem 'zip',                   '2.0.2', :require => 'zip/zip'
gem 'countries',             '0.3.0'
gem 'PageRankr',             '1.6.0', :require => 'page_rankr'
gem 'twitter',               '1.6.2'
gem 'settingslogic',         '2.0.6'
gem 'array_stats',           '0.6.0'
gem 'createsend',            '1.0.0' # Campaign Monitor

gem 'hoptoad_notifier',      '2.4.11'
gem 'prowl',                 '0.1.3'

gem 'addressable',           '2.2.6'
# Need to be updated manually until https://github.com/carlhuda/bundler/issues/67 is fixed.
gem 'stat_request_parser',   path: 'vendor/sv_stats_request_parser'


# Perf
gem 'dalli',                 '1.1.3'

group :production do
  gem 'rack-google-analytics', '0.9.2', :require => 'rack/google-analytics'
end

group :production, :staging do
  gem 'rack-ssl-enforcer', '0.2.2'
  gem 'rack-private'
end

group :development, :test do
  gem 'timecop'
  gem 'rspec-rails', '~> 2.6.0'

  gem 'ffaker'
  gem 'ruby-graphviz', :require => 'graphviz'
end

group :development do
  gem 'passenger'
  gem 'annotate'
  gem 'wirble'
  gem 'heroku'
  gem 'taps'
  gem 'silent-postgres'

  gem 'rb-fsevent', '~> 0.9.0.pre3'
  gem 'growl_notify'
  gem 'guard-bundler'
  gem 'guard-pow'
  gem 'guard-passenger'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'guard-livereload'
end

group :test do
  gem 'spork', '0.9.0.rc9'
  gem 'rspec-instafail'
  gem 'shoulda'
  gem 'capybara'
  gem 'webmock', '~> 1.6.4'
  gem 'vcr',     '~> 1.10.3'

  gem 'database_cleaner'
  gem 'factory_girl_rails', :require => false # loaded in spec_helper Spork.each_run
end
