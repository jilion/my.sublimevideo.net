source 'http://rubygems.org'

gem 'rails',         '3.0.0.beta3'

# Hosting
gem 'heroku'

# Auth
gem 'warden'
gem 'devise',        '>= 1.1.rc1'

# Internals
gem 'i18n'
gem 'haml'
gem 'state_machine'
gem 'responders'
gem 'uniquify'
gem 'delayed_job',   :git => 'git://github.com/thibaudgg/delayed_job'
gem 'will_paginate', :git => 'git://github.com/mislav/will_paginate.git', :branch => 'rails3'
gem 'has_scope',     :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',        :git => 'git://github.com/thibaudgg/jammit.git'

# File management
gem 'aws' # S3 support for carrierwave
gem 'carrierwave',   :git => 'git://github.com/jnicklas/carrierwave.git'

# Encoding
gem 'panda',         '>= 0.5.0'

# CDN
gem 'voxel_hapi',    :git => 'git://github.com/thibaudgg/voxel_hapi.git'

# Log analyzer
gem 'request-log-analyzer', :require => 'request_log_analyzer'

group :development do
  # bundler requires these gems in development
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'annotate'
  gem 'ffaker'
  
  # Ruby console
  gem 'looksee'
  gem 'wirble'
end

group :test do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  
  gem 'rev'
  gem 'watchr'
  gem 'growl'
  
  # gem "rspec",              :git => "git://github.com/rspec/rspec.git"
  # gem "rspec-core",         :git => "git://github.com/rspec/rspec-core.git"
  # gem "rspec-expectations", :git => "git://github.com/rspec/rspec-expectations.git"
  # gem "rspec-mocks",        :git => "git://github.com/rspec/rspec-mocks.git"
  # gem "rspec-rails",        :git => "git://github.com/rspec/rspec-rails.git"
  
  gem 'rspec',        '>= 2.0.0.beta.8'
  gem 'rspec-rails',  :git => 'git://github.com/rspec/rspec-rails.git', :ref => "d2fb9f35c7867225cd68758152f51dd3d1152a09"
  gem 'factory_girl', :git => 'git://github.com/danielb2/factory_girl'
  gem 'steak',        '0.4.0.a4'
  gem 'capybara'
  # gem 'capybara-envjs'
  gem 'email_spec'
  gem 'launchy'
  
  gem 'webmock'
  gem 'vcr'
  
  gem 'ruby-debug'
end

group :production do
  gem 'pg'
end