source :rubygems

gem 'rails',                '~> 3.0.0'
gem 'pg',                   '~> 0.9.0'
                            
gem 'libxml-ruby',          '~> 1.1.3', :require => 'libxml'
                            
gem 'i18n',                 '~> 0.4.1'
gem 'haml',                 '~> 3.0.18'
gem 'state_machine',        '~> 0.9.4'
gem 'responders',           :git => 'git://github.com/plataformatec/responders.git'
gem 'uniquify',             '~> 0.1.0'
gem 'delayed_job',          '~> 2.1.0.pre2'
gem 'will_paginate',        '~> 3.0.pre2'
gem 'has_scope',            :git => 'git://github.com/rymai/has_scope.git'
gem 'jammit',               :git => 'git://github.com/documentcloud/jammit.git'
gem 'meta_where',           :git => 'git://github.com/ernie/meta_where.git'
gem 'hoptoad_notifier',     '~> 2.3.4'
gem 'activemerchant',       '~> 1.7.1'
gem 'voxel_hapi',           :git => 'git://github.com/thibaudgg/voxel_hapi.git' # VoxCast CDN
gem 'request-log-analyzer', '~> 1.8.1', :require => 'request_log_analyzer'

gem 'devise',               '~> 1.1.2'
gem 'devise_invitable',     :git => 'git://github.com/rymai/devise_invitable.git'

gem 'memcached',            '~> 0.20.1'
gem 'dalli',                '~> 0.9.4'

gem 'aws',                  '~> 2.3.20'
gem 'carrierwave',          '~> 0.5.0.beta2'
gem 'RedCloth',             '~> 4.2.3'

gem 'bson_ext',             '1.0.4'
gem 'mongo',                '1.0.7'
gem 'mongoid',              '2.0.0.beta.17'

gem 'zip',                  '~> 2.0.2', :require => 'zip/zip'

group :production do
  gem 'rack-google-analytics', '~> 0.9.2', :require => 'rack/google-analytics'
end

group :production, :staging do
  gem 'rack-ssl-enforcer', :git => 'git://github.com/thibaudgg/rack-ssl-enforcer'
  gem 'rack-private',      '~> 0.1.5'
end

group :development do
  gem 'ffaker',        '>= 0.4.0'
  gem 'annotate'
  gem 'wirble'         # irbrc
  gem 'ruby-graphviz', :require => 'graphviz'
  gem 'heroku'
  gem 'heroku_tasks',  '~> 0.1.4'
  gem 'taps'           # heroku db pull/push
  gem 'rspec-rails',   '~> 2.0.0.beta.20'
end

group :test do
  gem 'pg', '~> 0.9.0'
  
  gem 'spork'
  gem 'rspactor',    '~> 0.7.beta.7'
  
  gem 'shoulda',     '~> 2.11.3'
  gem 'rspec-rails', '~> 2.0.0.beta.20'
  
  gem 'steak', '~> 0.4.0.beta.1'
  gem 'capybara'
  gem 'launchy'
  
  gem 'factory_girl_rails'
  gem 'webmock'
  gem 'vcr', '~> 1.1.1'
end