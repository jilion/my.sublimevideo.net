source "http://rubygems.org"

gem 'rake',                  '~> 0.8.7'

# gem 'rails',                 '3.1.0.rc5'
# Bundle edge Rails instead:
gem 'rails',     :git => 'git://github.com/rails/rails.git', :branch => '3-1-stable'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  # gem 'sass-rails', "~> 3.1.0.rc.5"
  gem 'sass-rails',   :git => 'git://github.com/rails/sass-rails.git', :branch => '3-1-stable'
  # gem 'coffee-rails', "~> 3.1.0.rc.5"
  gem 'coffee-rails', :git => 'git://github.com/rails/coffee-rails.git', :branch => '3-1-stable'
  gem 'eco'
  gem 'uglifier'
end


gem 'prototype-rails', :git => 'git://github.com/rymai/prototype-rails.git'
gem 'jquery-rails'
gem 'rails-backbone'

# Databases
gem 'pg',                    '~> 0.11.0'
# gem 'meta_where',            '1.0.4'
# gem 'arel',                  '2.2.0'
gem 'squeel', :git => 'git://github.com/ernie/squeel.git'

gem 'bson_ext',              '~> 1.3.1'
gem 'mongo',                 '~> 1.3.1'
gem 'mongoid',               '~> 2.1.9'

# Views
gem 'haml',                  '~> 3.1.2'
gem 'coffee-filter',         '~> 0.1.1'
# gem 'kaminari',              '~> 0.12.4'
gem 'kaminari', :git => 'git://github.com/amatsuda/kaminari.git'
gem 'liquid',                '~> 2.2.2'
gem 'RedCloth',              '~> 4.2.7'

# Auth / invitations
gem 'devise',                '~> 1.4.2'
# gem 'devise', :git => 'git://github.com/plataformatec/devise.git'
gem 'devise_invitable',      '~> 0.5.4'

# API
gem 'oauth',                 '~> 0.4.5'
gem 'oauth-plugin',          '~> 0.4.0.pre7'
gem 'acts_as_api',           '~> 0.3.8'
# gem 'rack-throttle',         :git => 'git://github.com/rymai/rack-throttle.git', :require => 'rack/throttle'

# Internals
gem 'delayed_job',           '~> 2.1.4'
gem 'rescue_me',             '~> 0.1.0'
gem 'configuration',         '~> 1.3.1'
gem 'libxml-ruby',           '~> 2.2.0', :require => 'libxml'

gem 'state_machine',         '~> 1.0.2'
gem 'paper_trail',           '~> 2.2.9'
gem 'uniquify',              '~> 0.1.0'

gem 'responders',            '~> 0.6.4'
gem 'has_scope',             '~> 0.5.1'

gem 'aws',                   '~> 2.5.6'
gem 'fog',                   '~> 0.10.0'
# gem 'carrierwave',           '0.5.6'
# For mongoid 2.1.x support, Until my patch is merged or mongoid support is extracted from carrierwave
# BUT since mongoid 2.1.x break so many specs, it's currently useless
gem 'carrierwave',           '~> 0.5.7'#,  :git => 'git://github.com/rymai/carrierwave.git'
gem 'carrierwave-mongoid',   '~> 0.1.1', :require => 'carrierwave/mongoid'# :git => 'git://github.com/jnicklas/carrierwave-mongoid.git'
gem 'voxel_hapi',            :git => 'git://github.com/thibaudgg/voxel_hapi.git', :branch => '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '~> 1.11.0', :require => 'request_log_analyzer'

# gem 'activemerchant',        '~> 1.9.1'
# Pull request: https://github.com/Shopify/active_merchant/pull/85
# gem 'activemerchant',        :git => 'git://github.com/ZenCocoon/active_merchant.git' # with the fix for Ogone#parse and more
gem 'activemerchant',        :git => 'git://github.com/rymai/active_merchant.git', :branch => '3ds_from_ZenCocoon'
gem 'public_suffix_service', '~> 0.9.0'
gem 'useragent',             :git => 'git://github.com/Jilion/useragent.git'

gem 'zip',                   '~> 2.0.2', :require => 'zip/zip'
gem 'countries',             '~> 0.5.3'
gem 'PageRankr',             '~> 2.0.2', :require => 'page_rankr'
gem 'twitter',               '~> 1.6.2'
gem 'settingslogic',         '~> 2.0.6'
gem 'array_stats',           '~> 0.6.0'
gem 'createsend',            '~> 0.3.2' # Campaign Monitor

gem 'hoptoad_notifier',      '~> 2.4.11'
gem 'prowl',                 '~> 0.1.3'

gem 'addressable',           '~> 2.2.6'

# Perf
gem 'dalli',                 '~> 1.0.5'

group :production do
  gem 'rack-google-analytics', '~> 0.9.2', :require => 'rack/google-analytics'
end

group :production, :staging do
  gem 'rack-ssl-enforcer', '~> 0.2.3'
  gem 'rack-private'
end

group :development, :test do
  gem 'timecop'
  gem 'rspec-rails', '~> 2.6.1'
  gem 'ruby-debug19'
end

group :development do
  gem 'rails-dev-tweaks', '~> 0.4.0'
  gem 'ffaker'
  gem 'annotate'
  gem 'wirble'
  gem 'ruby-graphviz', :require => 'graphviz'
  gem 'heroku'
  gem 'taps'
  gem 'silent-postgres'
end

group :guard do
  gem 'rb-fsevent', :git => 'git://github.com/ttilley/rb-fsevent.git', :branch => 'pre-compiled-gem-one-off'
  gem 'growl_notify'
  gem 'guard', :git => 'git://github.com/guard/guard.git'
  gem 'guard-bundler'
  gem 'guard-pow'
  gem 'guard-livereload'
  gem 'guard-spork'
  gem 'guard-rspec'
end

group :test do
  gem 'spork', '~> 0.9.0.rc9'
  gem 'fuubar'
  gem 'shoulda-matchers', :git => 'git://github.com/thoughtbot/shoulda-matchers.git'
  gem 'capybara'
  gem 'webmock', '~> 1.6.4'
  gem 'typhoeus'
  gem 'vcr',     '~> 1.10.3'

  gem 'database_cleaner'
  gem 'factory_girl_rails', :require => false # loaded in spec_helper Spork.each_run
end
