source 'http://rubygems.org'

gem 'rails',            '3.0.0.beta4'

gem 'libxml-ruby',      '1.1.3', :require => 'libxml'

gem 'i18n',             '0.4.1'
gem 'haml',             '3.0.13'
gem 'state_machine',    '0.9.3'
gem 'responders',       :git => 'git://github.com/plataformatec/responders.git'
gem 'uniquify',         '0.1.0'
gem 'delayed_job',      :git => 'git://github.com/thibaudgg/delayed_job.git'
gem 'will_paginate',    :git => 'git://github.com/mislav/will_paginate.git', :branch => 'rails3'
gem 'has_scope',        :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',           :git => 'git://github.com/thibaudgg/jammit.git'
gem 'meta_where',       '0.5.2'
gem 'hoptoad_notifier', '2.3.2'
gem 'activemerchant',   '1.5.1'
gem 'panda',            '0.6.4' # Encoding
gem 'voxel_hapi',       :git => 'git://github.com/thibaudgg/voxel_hapi.git' # VoxCast CDN
gem 'request-log-analyzer', :require => 'request_log_analyzer'

gem 'devise',           '>= 1.1.rc2' # Auth
gem 'devise_invitable', :git => 'git://github.com/rymai/devise_invitable.git'

gem 'system_timer',     '1.0.0' # Only on Ruby 1.8, used by memcache-client
gem 'memcache-client',  '1.8.5'
gem 'memcached',        '0.19.10'

gem 'aws',              '>= 2.3.12'
# While the official repo is not up to date with the new name of MiniMagick::Error
gem 'carrierwave',      :git => 'git://github.com/samlown/carrierwave.git' #'git://github.com/jnicklas/carrierwave.git'
gem 'mini_magick',      '1.2.5'
gem 'RedCloth'

gem 'ffaker',           '0.4.0'

group :production do
  gem 'pg',             '0.9.0'
end

# Heroku hack
if RUBY_PLATFORM =~ /darwin/
  
  group :development do
    gem 'sqlite3-ruby', :require => 'sqlite3'
    gem 'annotate'
    gem 'wirble' # irbrc 
    gem 'ruby-graphviz', :require => 'graphviz'
    gem 'rspec-rails', '>= 2.0.0.beta.17'
  end
  
  group :test do
    gem 'pg'
    gem 'parallel'
    
    gem 'spork'
    gem 'rspactor', '>= 0.7.beta.4'
    
    gem 'shoulda'
    gem 'rspec-rails', '>= 2.0.0.beta.17'
    
    gem 'steak', '>= 0.4.0.beta.1'
    gem 'capybara'
    # gem 'capybara-envjs'
    gem 'launchy'
    
    gem 'factory_girl_rails'
    gem 'webmock'
    gem 'vcr', '>= 1.0.2'
  end
  
end