source 'http://rubygems.org'

gem 'rails', '3.0.0.beta4'

gem 'heroku' # Hosting
gem 'i18n'
gem 'haml'
gem 'state_machine',    :git => 'git://github.com/pluginaweek/state_machine.git'
gem 'responders'
gem 'uniquify'
gem 'delayed_job',      :git => 'git://github.com/thibaudgg/delayed_job'
gem 'will_paginate',    :git => 'git://github.com/mislav/will_paginate.git', :branch => 'rails3'
gem 'has_scope',        :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',           :git => 'git://github.com/thibaudgg/jammit.git'
gem 'meta_where'
gem 'hoptoad_notifier'
gem 'activemerchant'
gem 'panda' # Encoding
gem 'voxel_hapi',       :git => 'git://github.com/thibaudgg/voxel_hapi.git' # VoxCast CDN
gem 'request-log-analyzer', :require => 'request_log_analyzer'

gem 'warden'
gem 'devise', '>= 1.1.rc2' # Auth

gem 'system_timer' # only on Ruby 1.8, used by memcache-client
gem 'memcache-client'
gem 'memcached'

gem 'http_connection',  :git => 'git://github.com/thibaudgg/http_connection.git'
gem 'aws',              '>= 2.3.12'
gem 'carrierwave',      :git => 'git://github.com/jnicklas/carrierwave.git'

group :development do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'annotate'
  gem 'ffaker'
  gem 'wirble' # irbrc 
  gem 'ruby-graphviz', :require => 'graphviz'
end

group :test do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  # gem 'parallel'
  # gem 'hydra'
  
  gem 'rev'
  gem 'watchr'
  gem 'growl'
  gem 'spork'
  # gem 'rspactor',     :path => '/Users/Thibaud/Vault/Dropbox/Development/Code/rspactor2'
  
  gem "shoulda"
  gem "rspec-rails",        :git => "git://github.com/rspec/rspec-rails.git"
  gem "rspec",              :git => "git://github.com/rspec/rspec.git"
  gem "rspec-core",         :git => "git://github.com/rspec/rspec-core.git"
  gem "rspec-expectations", :git => "git://github.com/rspec/rspec-expectations.git"
  gem "rspec-mocks",        :git => "git://github.com/rspec/rspec-mocks.git"
  
  gem 'steak', '>= 0.4.0.beta.1'
  gem 'capybara'
  # gem 'capybara-envjs'
  gem 'launchy'
  
  gem 'factory_girl_rails'
  gem 'webmock'
  gem 'vcr'
end

group :production do
  gem 'pg'
end