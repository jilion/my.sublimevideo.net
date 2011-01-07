source :rubygems

gem 'bundler',               '1.0.7'

# gem 'rails',                 '~> 3.0.3'
gem 'rails',                 :git => 'git://github.com/thibaudgg/rails.git', :branch => 'spork' # 3.0.3
gem 'rack',                  '1.2.1'
gem 'arel',                  '2.0.6'
gem 'pg',                    '0.10.0'

gem 'libxml-ruby',           '1.1.3', :require => 'libxml'

gem 'i18n',                  '0.5.0'
gem 'haml',                  '3.0.24'
gem 'state_machine',         '0.9.4'
gem 'responders',            '0.6.2'
gem 'uniquify',              '0.1.0'
gem 'delayed_job',           '2.1.1' # 2.1.2 is failing !!!!!
gem 'will_paginate',         '3.0.pre2'
gem 'has_scope',             :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',                '0.5.4'
gem 'meta_where',            '0.9.10'
gem 'hoptoad_notifier',      '2.4.0'
gem 'prowl',                 '0.1.3'
# gem 'activemerchant',        '~> 1.9.1'
# Pull request: https://github.com/Shopify/active_merchant/pull/64
gem 'activemerchant',        :git => 'git://github.com/rymai/active_merchant.git' # with the fix for Ogone#parse
gem 'voxel_hapi',            :git => 'git://github.com/thibaudgg/voxel_hapi.git', :branch => '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '1.9.10', :require => 'request_log_analyzer'
gem 'public_suffix_service', '0.8.1'
gem 'RedCloth',              '4.2.3'
gem 'liquid',                '2.2.2'

# gem 'devise',                '~> 1.1.5'
# gem 'devise',                :git => 'git://github.com/thibaudgg/devise.git', :branch => 'spork' # 1.1.5
gem 'devise',                :git => 'git://github.com/rymai/devise.git', :branch => 'spork' # 1.1.5
gem 'devise_invitable',      :git => 'git://github.com/rymai/devise_invitable.git'

gem 'dalli',                 '1.0.1'

gem 'aws',                   '2.3.34'
gem 'fog',                   '0.4.0'
gem 'carrierwave',           '0.5.1'

gem 'bson_ext',              '1.1.5'
gem 'mongo',                 '1.1.5'
# gem 'mongoid',               '~> 2.0.0.beta.20'
gem 'mongoid',               :git => 'git://github.com/thibaudgg/mongoid.git', :branch => 'spork' # 2.0.0.beta.20

gem 'zip',                   '2.0.2', :require => 'zip/zip'
gem 'countries',             '0.3.0'
gem 'PageRankr',             '1.6.0', :require => 'page_rankr'
gem 'array_stats',           '0.6.0'
gem 'rescue_me',             '0.1.0'
gem 'paper_trail',           '1.6.4'
gem 'settingslogic',         '2.0.6'
gem 'pdfkit',                '0.5.0'
gem 'createsend',            '0.2.0' # Campaign Monitor

group :production do
  gem 'rack-google-analytics', '0.9.2', :require => 'rack/google-analytics'
end

group :production, :staging do
  gem 'rack-ssl-enforcer', '0.2.0'
  gem 'rack-private',      '0.1.5'
end

group :development, :test do
  gem 'silent-postgres'
  gem 'rspec-rails',   '~> 2.4.1'
  gem 'passenger',     '~> 3.0.2'
  gem 'timecop',       '~> 0.3.5'
end

group :development do
  gem 'ffaker',        '~> 1.0.0'
  gem 'annotate',      '~> 2.4.0'
  gem 'wirble',        '~> 0.1.3'
  gem 'ruby-graphviz', :require => 'graphviz'
  gem 'heroku',        '~> 1.16.2'
  gem 'heroku_tasks',  '~> 0.1.4'
  gem 'taps',          '~> 0.3.14' # heroku db pull/push
  gem 'silent-postgres'
end

group :test do
  gem 'growl'
  gem 'spork',              '~> 0.9.0.rc2'
  gem 'rb-fsevent',         '~> 0.3.9'
  gem 'guard',              :git => "git://github.com/guard/guard.git"
  gem 'guard-ego'
  gem 'guard-bundler'
  gem 'guard-passenger'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'livereload'
  gem 'guard-livereload'

  gem 'database_cleaner',   '>= 0.6'
  gem 'capybara',           '~> 0.4.0'
  gem 'steak',              '1.0.0.rc.2'
  # gem 'akephalos',          '~> 0.2.4'
  # gem 'capybara-envjs',     '~> 0.4.0'
  gem 'webmock',            '~> 1.6.1'
  gem 'vcr',                '~> 1.4.0'

  gem 'shoulda',            '~> 2.11.3'
  gem 'factory_girl_rails', '~> 1.0.1', :require => false # loaded in spec_helper Spork.each_run
end
