source 'http://rubygems.org'

gem 'rails', '3.0.0.beta4'

gem 'libxml-ruby', '1.1.3', :require => 'libxml'

gem 'i18n'
gem 'haml'
gem 'state_machine'
gem 'responders',       :git => 'git://github.com/plataformatec/responders.git'
gem 'uniquify'
gem 'delayed_job',      :git => 'git://github.com/thibaudgg/delayed_job.git'
gem 'will_paginate',    :git => 'git://github.com/mislav/will_paginate.git', :branch => 'rails3'
gem 'has_scope',        :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',           :git => 'git://github.com/thibaudgg/jammit.git'
gem 'meta_where'
gem 'hoptoad_notifier'
gem 'activemerchant'
gem 'panda', '>= 0.6.4' # Encoding
gem 'voxel_hapi',       :git => 'git://github.com/thibaudgg/voxel_hapi.git' # VoxCast CDN
gem 'request-log-analyzer', :require => 'request_log_analyzer'

gem 'devise', '>= 1.1.rc2' # Auth
gem 'devise_invitable', :git => 'git://github.com/rymai/devise_invitable.git'

gem 'system_timer' # Only on Ruby 1.8, used by memcache-client
gem 'memcache-client'
gem 'memcached'

gem 'aws',              '>= 2.3.12'
# While the official repo is not up to date with the new name of MiniMagick::Error
gem 'carrierwave',      :git => 'git://github.com/samlown/carrierwave.git' #'git://github.com/jnicklas/carrierwave.git'
gem 'mini_magick',      '1.2.5'
gem 'RedCloth'

gem 'ffaker'

group :production do
  gem 'pg'
end

if RUBY_PLATFORM =~ /darwin/
  
  group :development do
    gem 'sqlite3-ruby', :require => 'sqlite3'
    gem 'annotate'
    gem 'wirble' # irbrc 
    gem 'ruby-graphviz', :require => 'graphviz'
  end
  
  group :test do
    gem 'pg'
    gem 'parallel'
    
    gem 'spork'
    gem 'rspactor', '>= 0.7.beta.1'
    
    gem 'shoulda'
    gem 'rspec-rails', '>= 2.0.0.beta.15'
    # gem "rspec-rails",        :git => "git://github.com/rspec/rspec-rails.git"
    # gem "rspec",              :git => "git://github.com/rspec/rspec.git"
    # gem "rspec-core",         :git => "git://github.com/rspec/rspec-core.git"
    # gem "rspec-expectations", :git => "git://github.com/rspec/rspec-expectations.git"
    # gem "rspec-mocks",        :git => "git://github.com/rspec/rspec-mocks.git"
    
    gem 'steak', '>= 0.4.0.beta.1'
    gem 'capybara'
    # gem 'capybara-envjs'
    gem 'launchy'
    
    gem 'factory_girl_rails'
    gem 'webmock'
    gem 'vcr', :git => 'git://github.com/myronmarston/vcr', :ref => "0ec9ab51cbaf7c4d79862a500304d91e3ff585ce"
  end
  
end