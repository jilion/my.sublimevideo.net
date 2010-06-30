source 'http://rubygems.org'

gem 'rails', '3.0.0.beta4'

gem 'libxml-ruby', :require => 'libxml'

gem 'heroku' # Hosting
gem 'i18n'
gem 'haml'
gem 'state_machine'
gem 'responders'
gem 'uniquify'
gem 'delayed_job',      :git => 'http://github.com/thibaudgg/delayed_job.git'
gem 'will_paginate',    :git => 'http://github.com/mislav/will_paginate.git', :branch => 'rails3'
gem 'has_scope',        :git => 'http://github.com/rymai/has_scope.git'
gem 'jammit',           :git => 'http://github.com/thibaudgg/jammit.git'
gem 'meta_where'
gem 'hoptoad_notifier'
gem 'activemerchant'
gem 'panda' # Encoding
gem 'voxel_hapi',       :git => 'http://github.com/thibaudgg/voxel_hapi.git' # VoxCast CDN
gem 'request-log-analyzer', :require => 'request_log_analyzer'

gem 'devise', '>= 1.1.rc2' # Auth
gem 'devise_invitable', :git => 'http://github.com/rymai/devise_invitable.git'

gem 'system_timer' # Only on Ruby 1.8, used by memcache-client
gem 'memcache-client'
gem 'memcached'

gem 'aws',              '>= 2.3.12'
gem 'carrierwave',      :git => 'http://github.com/jnicklas/carrierwave.git'
gem 'mini_magick'
gem 'RedCloth'

group :development do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'annotate'
  gem 'ffaker'
  gem 'wirble' # irbrc 
  gem 'ruby-graphviz', :require => 'graphviz'
end

group :test do
  gem 'pg'
  gem 'parallel'
  
  gem 'growl' # needed by RSpactor
  gem 'spork'
  
  gem 'shoulda'
  gem 'rspec-rails', '>= 2.0.0.beta.14.2'
  # gem "rspec-rails",        :git => "http://github.com/rspec/rspec-rails.git"
  # gem "rspec",              :git => "http://github.com/rspec/rspec.git"
  # gem "rspec-core",         :git => "http://github.com/rspec/rspec-core.git"
  # gem "rspec-expectations", :git => "http://github.com/rspec/rspec-expectations.git"
  # gem "rspec-mocks",        :git => "http://github.com/rspec/rspec-mocks.git"
  
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