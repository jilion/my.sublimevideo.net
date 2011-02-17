source :rubygems

gem 'bundler',               '~> 1.0.10'

gem 'rails',                 '~> 3.0.4'
gem 'pg',                    '0.10.1'
gem 'i18n',                  '~> 0.5.0'
# gem 'mail',                  '~> 2.2.15'

gem 'configuration',         '~> 1.2.0'
gem 'libxml-ruby',           '1.1.3', :require => 'libxml'

gem 'haml',                  '3.0.24'
gem 'state_machine',         '0.9.4'
gem 'responders',            '0.6.2'
gem 'uniquify',              '0.1.0'
gem 'delayed_job',           '2.1.3'
gem 'will_paginate',         '3.0.pre2'
gem 'has_scope',             :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',                '0.6.0'
gem 'meta_where',            '~> 1.0.3'
gem 'hoptoad_notifier',      '~> 2.4.5'
gem 'prowl',                 '0.1.3'
# gem 'activemerchant',        '~> 1.9.1'
# Pull request: https://github.com/Shopify/active_merchant/pull/64
gem 'activemerchant',        :git => 'git://github.com/rymai/active_merchant.git' # with the fix for Ogone#parse
gem 'voxel_hapi',            :git => 'git://github.com/thibaudgg/voxel_hapi.git', :branch => '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '1.9.10', :require => 'request_log_analyzer'
gem 'public_suffix_service', '0.8.1'
gem 'RedCloth',              '4.2.3'
gem 'liquid',                '2.2.2'

gem 'devise',                '1.1.6'
gem 'devise_invitable',      :git => 'git://github.com/rymai/devise_invitable.git'

gem 'dalli',                 '~> 1.0.2'

gem 'aws',                   '2.3.34' # bugs in 2.4.2
gem 'fog',                   '0.5.1'
gem 'carrierwave',           '0.5.1'

gem 'bson_ext',              '~> 1.2.2'
gem 'mongo',                 '~> 1.2.2'
gem 'mongoid',               '~> 2.0.0.rc.7' # '2.0.0.beta.20'

gem 'zip',                   '2.0.2', :require => 'zip/zip'
gem 'countries',             '0.3.0'
gem 'PageRankr',             '1.6.0', :require => 'page_rankr'
gem 'array_stats',           '0.6.0'
gem 'rescue_me',             '0.1.0'
gem 'paper_trail',           '2.0.0'
gem 'settingslogic',         '2.0.6'
gem 'createsend',            '0.2.1' # Campaign Monitor

gem 'useragent', :git => 'git://github.com/Jilion/useragent.git'

group :production do
  gem 'rack-google-analytics', '0.9.2', :require => 'rack/google-analytics'
end

group :production, :staging do
  gem 'rack-ssl-enforcer', '0.2.1'
  gem 'rack-private',      '0.1.5'
end

group :development, :test do
  # gem 'silent-postgres'
  gem 'rspec-rails',   '~> 2.5.0'
  gem 'passenger',     '~> 3.0.2'
  gem 'timecop',       '~> 0.3.5'
end

group :development do
  gem 'ffaker',        '~> 1.2.0'
  gem 'annotate',      '~> 2.4.0'
  gem 'wirble',        '~> 0.1.3'
  gem 'ruby-graphviz', :require => 'graphviz'
  gem 'heroku',        '~> 1.17.10'
  gem 'heroku_tasks',  '~> 0.1.4'
  gem 'taps',          '~> 0.3.14' # heroku db pull/push
  gem 'silent-postgres'
end

group :test do
  gem 'growl'
  gem 'spork',              '~> 0.9.0.rc3'
  gem 'rb-fsevent',         '~> 0.3.9'
  gem 'guard'
  gem 'guard-ego'
  gem 'guard-bundler'
  gem 'guard-passenger'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'livereload'
  gem 'guard-livereload'

  gem 'database_cleaner'
  # gem 'steak',              '1.0.0.rc.2'
  gem 'capybara',           '~> 0.4.1.2'
  # gem 'akephalos',          '~> 0.2.4'
  # gem 'capybara-envjs',     '~> 0.4.0'
  gem 'webmock',            '~> 1.6.2'
  gem 'vcr',                '~> 1.6.0'

  gem 'shoulda',            '~> 2.11.3'
  gem 'factory_girl_rails', '~> 1.0.1', :require => false # loaded in spec_helper Spork.each_run
end
