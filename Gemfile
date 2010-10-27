source :rubygems

gem 'bundler',               '~> 1.0'

gem 'rails',                 '~> 3.0.1'
gem 'rack',                  '~> 1.2.1'
gem 'pg',                    '~> 0.9.0'

gem 'libxml-ruby',           '~> 1.1.3', :require => 'libxml'

gem 'i18n',                  '~> 0.4.1'
gem 'haml',                  '~> 3.0.22'
gem 'state_machine',         '~> 0.9.4'
gem 'responders',            '~> 0.6.2'
gem 'uniquify',              '~> 0.1.0'
gem 'delayed_job',           '~> 2.1.0.pre2'
gem 'will_paginate',         '~> 3.0.pre2'
gem 'has_scope',             :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',                '~> 0.5.3'
gem 'meta_where',            '~> 0.9.5'
gem 'hoptoad_notifier',      '~> 2.3.10'
gem 'prowl',                 '~> 0.1.3'
gem 'activemerchant',        '~> 1.9.0'
gem 'voxel_hapi',            :git => 'git://github.com/thibaudgg/voxel_hapi.git', :branch => '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '~> 1.9.6', :require => 'request_log_analyzer'
gem 'public_suffix_service', '~> 0.6.0'
gem 'RedCloth',              '~> 4.2.3'
gem 'liquid',                '~> 2.2.2'

gem 'devise',                '~> 1.1.3'
gem 'devise_invitable',      :git => 'git://github.com/rymai/devise_invitable.git'

gem 'memcached',             '~> 0.20.1'
gem 'dalli',                 '~> 0.10.1'

gem 'aws',                   '~> 2.3.22'
gem 'fog',                   '~> 0.3.13' # for carrierwave 0.5 final
gem 'carrierwave',           '~> 0.5.0'

gem 'bson_ext',              '~> 1.1.1'
gem 'mongo',                 '~> 1.0.9'
gem 'mongoid',               '~> 2.0.0.beta.19'

gem 'zip',                   '~> 2.0.2', :require => 'zip/zip'
gem 'countries',             '~> 0.3.0'
gem 'PageRankr',             '~> 1.4.3', :require => 'page_rankr'
gem 'array_stats',           '~> 0.6.0'
gem 'rescue_me',             '~> 0.1.0'

group :production do
  gem 'rack-google-analytics', '~> 0.9.2', :require => 'rack/google-analytics'
end

group :production, :staging do
  gem 'rack-ssl-enforcer', '~> 0.1.8'
  gem 'rack-private',      '~> 0.1.5'
end

group :development, :test do
  gem 'silent-postgres'
  gem 'rspec-rails',   '~> 2.0.1'
end

group :development do
  gem 'ffaker',        '>= 0.4.0'
  gem 'annotate',      '~> 2.4.0'
  gem 'wirble',        '~> 0.1.3'
  gem 'ruby-graphviz', :require => 'graphviz'
  gem 'heroku',        '~> 1.11.0'
  gem 'heroku_tasks',  '~> 0.1.4'
  gem 'taps',          '~> 0.3.13' # heroku db pull/push
  gem 'timecop',       '~> 0.3.5'
  gem 'silent-postgres'
end

group :test do
  gem 'database_cleaner', '>= 0.6'
  gem 'growl'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-livereload'
  gem 'guard-bundler'
  
  gem 'shoulda',            '~> 2.11.3'
  gem 'steak',              '~> 1.0.0.rc.1'
  gem 'capybara',           '~> 0.4.0'
  # gem 'capybara-envjs',     '~> 0.4.0'
  # gem 'akephalos',        '~> 0.2.4'
  
  gem 'webmock',            '~> 1.4.0'
  gem 'vcr',                '~> 1.2.0'
  
  gem 'spork',              '~> 0.9.0.rc2'
  gem 'factory_girl_rails', '~> 1.0.0'
end