source :rubygems

gem 'bundler',               '1.0.10'

gem 'rails',                 '3.0.5'

# Databases
gem 'pg',                    '0.10.1'
gem 'meta_where',            '1.0.4'
gem 'bson_ext',              '1.2.4'
gem 'mongo',                 '1.2.4'
gem 'mongoid',               '~> 2.0.0.rc.7'

# Internals
gem 'delayed_job',           '2.1.3'
gem 'rescue_me',             '0.1.0'
gem 'configuration',         '1.2.0'
gem 'libxml-ruby',           '1.1.3', :require => 'libxml'

gem 'state_machine',         '0.9.4'
gem 'paper_trail',           '2.0.0'
gem 'uniquify',              '0.1.0'

gem 'responders',            '0.6.2'
gem 'has_scope',             :git => 'git://github.com/rymai/has_scope.git'

gem 'aws',                   '2.3.34' # bugs in 2.4.2
gem 'fog',                   '0.6.0'
gem 'carrierwave',           '0.5.2'
gem 'voxel_hapi',            :git => 'git://github.com/thibaudgg/voxel_hapi.git', :branch => '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '1.9.10', :require => 'request_log_analyzer'

# gem 'activemerchant',        '~> 1.9.1'
# Pull request: https://github.com/Shopify/active_merchant/pull/85
gem 'activemerchant',        :git => 'git://github.com/ZenCocoon/active_merchant.git' # with the fix for Ogone#parse and more
gem 'public_suffix_service', '0.8.1'
gem 'useragent', :git => 'git://github.com/Jilion/useragent.git'

gem 'zip',                   '2.0.2', :require => 'zip/zip'
gem 'countries',             '0.3.0'
gem 'PageRankr',             '1.6.0', :require => 'page_rankr'

gem 'settingslogic',         '2.0.6'
gem 'array_stats',           '0.6.0'
gem 'createsend',            '0.2.1' # Campaign Monitor

gem 'hoptoad_notifier',      '2.4.6'
gem 'prowl',                 '0.1.3'

# Views
gem 'haml',                  '3.0.24'
gem 'kaminari',              '~> 0.10.4'
gem 'jammit',                '0.6.0'
gem 'liquid',                '2.2.2'
gem 'RedCloth',              '4.2.3'

# Auth / invitations
gem 'devise',                '1.1.7'
gem 'devise_invitable',      :git => 'git://github.com/rymai/devise_invitable.git'

# Perf
gem 'dalli',                 '1.0.2'

group :production do
  gem 'rack-google-analytics', '0.9.2', :require => 'rack/google-analytics'
end

group :production, :staging do
  gem 'rack-ssl-enforcer', '0.2.1'
  gem 'rack-private',      '0.1.5'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'passenger'
  gem 'timecop'
end

group :development do
  gem 'ffaker'
  gem 'annotate'
  gem 'wirble'
  gem 'ruby-graphviz', :require => 'graphviz'
  gem 'heroku'
  gem 'heroku_tasks'
  gem 'taps'
  gem 'silent-postgres'
end

group :test do
  gem 'spork',              '~> 0.9.0.rc4'
  gem 'rb-fsevent'
  gem 'growl'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-passenger'
  gem 'guard-spork'
  gem 'guard-rspec'
  gem 'livereload'
  gem 'guard-livereload'

  gem 'shoulda'
  gem 'capybara', :git => 'git://github.com/jnicklas/capybara.git'
  gem 'webmock'
  gem 'vcr'

  gem 'database_cleaner'
  gem 'factory_girl_rails', :require => false # loaded in spec_helper Spork.each_run
end
