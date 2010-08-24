source :rubygems

gem 'rails',                 '3.0.0.rc2'

gem 'libxml-ruby',           '~> 1.1.3', :require => 'libxml'

gem 'i18n',                  '~> 0.4.1'
gem 'haml',                  '~> 3.0.16'
gem 'state_machine',         '~> 0.9.4'
gem 'responders',            :git => 'git://github.com/plataformatec/responders.git'
gem 'uniquify',              '~> 0.1.0'
gem 'delayed_job',           :git => 'git://github.com/collectiveidea/delayed_job.git'
gem 'will_paginate',         '~> 3.0.pre2'
gem 'has_scope',             :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',                :git => 'git://github.com/thibaudgg/jammit.git'
gem 'meta_where',            :git => 'git://github.com/ernie/meta_where.git'
gem 'hoptoad_notifier',      '~> 2.3.4'
gem 'activemerchant',        '~> 1.7.1'
gem 'voxel_hapi',            :git => 'git://github.com/thibaudgg/voxel_hapi.git' # VoxCast CDN
gem 'request-log-analyzer',  '~> 1.8.0', :require => 'request_log_analyzer'

gem 'devise',                '~> 1.1.1'
gem 'devise_invitable',      :git => 'git://github.com/thibaudgg/devise_invitable.git'

gem 'system_timer',          '~> 1.0.0' # Only on Ruby 1.8, used by memcache-client
gem 'memcache-client',       '~> 1.8.5'
gem 'memcached',             '~> 0.20.1'

gem 'aws',                   '~> 2.3.20'
gem 'carrierwave',           '~> 0.5.0.beta2'
gem 'RedCloth',              '~> 4.2.3'

gem 'mongoid',               :git => 'git://github.com/mongoid/mongoid.git'
gem 'bson_ext',              '~> 1.0.4'

group :production, :staging do
  gem 'pg',                  '~> 0.9.0'
  gem 'rack-ssl-enforcer',   :git => 'git://github.com/thibaudgg/rack-ssl-enforcer.git'
  gem 'rack-staging',        :git => 'git://github.com/thibaudgg/rack-staging.git'
end

group :development do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'ffaker',       '>= 0.4.0'
  gem 'annotate'
  gem 'wirble' # irbrc
  gem 'ruby-graphviz', :require => 'graphviz'
  gem 'heroku'
  gem 'heroku_tasks', :git => 'git://github.com/thibaudgg/heroku_tasks.git'
  gem 'taps' # heroku db pull/push
  
  gem 'rspec-rails', '~> 2.0.0.beta.20'
end

group :test do
  gem 'pg', '~> 0.9.0'
  
  gem 'spork'
  gem 'rspactor', '~> 0.7.beta.6'
  
  gem 'shoulda'
  gem 'rspec-rails', '~> 2.0.0.beta.20'
  
  gem 'steak', '~> 0.4.0.beta.1'
  gem 'capybara'
  gem 'launchy'
  
  gem 'factory_girl_rails'
  gem 'webmock'
  gem 'vcr', '~> 1.1.0'
end