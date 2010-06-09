source 'http://rubygems.org'

gem 'rails', '3.0.0.beta3'

# Hosting
gem 'heroku'

# Auth
gem 'warden'
gem 'devise', '>= 1.1.rc1'

# Internals
gem 'i18n'
gem 'haml'
gem 'state_machine'
gem 'responders'
gem 'uniquify'
gem 'delayed_job',      :git => 'git://github.com/thibaudgg/delayed_job'
gem 'will_paginate',    :git => 'git://github.com/mislav/will_paginate.git', :branch => 'rails3'
gem 'has_scope',        :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',           :git => 'git://github.com/thibaudgg/jammit.git'
gem 'meta_where'

gem 'system_timer'

gem 'memcached'
# gem 'memcache'

# File management
gem 'http_connection',  :git => 'git://github.com/thibaudgg/http_connection.git'
gem 'aws' # S3 support for carrierwave
gem 'carrierwave',      :git => 'git://github.com/jnicklas/carrierwave.git'

# Encoding
gem 'panda', '>= 0.5.0'

# CDN
gem 'voxel_hapi',       :git => 'git://github.com/thibaudgg/voxel_hapi.git'

# Log analyzer
gem 'request-log-analyzer', :require => 'request_log_analyzer'

group :development do
  gem 'exceptional'
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'annotate'
  gem 'ffaker'
  
  # Ruby console
  gem 'looksee'
  gem 'wirble'
  
end

group :test do
  gem 'exceptional'
  gem 'sqlite3-ruby', :require => 'sqlite3'
  
  gem 'rev'
  gem 'watchr'
  gem 'growl'
  gem 'spork'
  
  gem 'rspec',        '>= 2.0.0.beta.11'
  gem 'rspec-rails',  '>= 2.0.0.beta.11'
  
  gem 'steak',        '>= 0.4.0.beta.1'
  gem 'capybara'
  gem 'capybara-envjs'
  gem 'launchy'
  
  gem 'email_spec',   :git => 'git://github.com/bmabey/email-spec', :branch => 'rails3'
  gem 'factory_girl', :git => 'git://github.com/thoughtbot/factory_girl.git', :branch => 'fixes_for_rails3'
  
  gem 'webmock'
  gem 'vcr'
end

group :production do
  gem 'pg'
end