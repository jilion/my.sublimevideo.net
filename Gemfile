source :rubygems

gem 'bundler',               '1.0.12'

gem 'rails',                 '3.0.7'

# Databases
gem 'pg',                    '0.10.1'
gem 'meta_where',            '1.0.4'
gem 'bson_ext',              '1.3.0'
gem 'mongo',                 '1.3.0'
gem 'mongoid',               '2.0.1'

# Views
gem 'haml',                  '3.0.25'
gem 'kaminari',              '0.11.0'
gem 'jammit',                '0.6.0'
gem 'liquid',                '2.2.2'
gem 'RedCloth',              '4.2.3'

# Auth / invitations
gem 'devise',                '1.1.9'
gem 'devise_invitable',      :git => 'git://github.com/rymai/devise_invitable.git'

# Internals
gem 'delayed_job',           '2.1.4'
gem 'rescue_me',             '0.1.0'
gem 'configuration',         '1.2.0'
gem 'libxml-ruby',           '1.1.3', :require => 'libxml'

gem 'state_machine',         '0.10.4'
gem 'paper_trail',           '2.2.2'
gem 'uniquify',              '0.1.0'

gem 'responders',            '0.6.2'
gem 'has_scope',             :git => 'git://github.com/rymai/has_scope.git'

gem 'aws',                   '2.3.34' # bugs in 2.4.2
gem 'fog',                   '0.7.2'
gem 'carrierwave',           '0.5.3'
gem 'voxel_hapi',            :git => 'git://github.com/thibaudgg/voxel_hapi.git', :branch => '1.9.2' # VoxCast CDN
gem 'request-log-analyzer',  '1.9.10', :require => 'request_log_analyzer'

# gem 'activemerchant',        '~> 1.9.1'
# Pull request: https://github.com/Shopify/active_merchant/pull/85
# gem 'activemerchant',        :git => 'git://github.com/ZenCocoon/active_merchant.git' # with the fix for Ogone#parse and more
gem 'activemerchant',        :git => 'git://github.com/rymai/active_merchant.git', :branch => '3ds_from_ZenCocoon'
gem 'public_suffix_service', '0.8.1'
gem 'useragent', :git => 'git://github.com/Jilion/useragent.git'

gem 'zip',                   '2.0.2', :require => 'zip/zip'
gem 'countries',             '0.3.0'
gem 'PageRankr',             '1.6.0', :require => 'page_rankr'
gem 'twitter',               '1.3.0'
gem 'settingslogic',         '2.0.6'
gem 'array_stats',           '0.6.0'
# gem 'createsend',            '0.2.1' # Campaign Monitor
gem 'createsend',            :git => 'git://github.com/rymai/createsend-ruby.git' # update dependencies for hashie (was conflicting with the Twitter gem)

gem 'hoptoad_notifier',      '2.4.9'
gem 'prowl',                 '0.1.3'

# Perf
gem 'dalli',                 '1.0.3'

group :production do
  gem 'rack-google-analytics', '0.9.2', :require => 'rack/google-analytics'
end

group :production, :staging do
  gem 'rack-ssl-enforcer', '0.2.1'
  gem 'rack-private'
end

group :development, :test do
  gem "rspec-rails",        :git => "git://github.com/rspec/rspec-rails.git"
  gem "rspec",              :git => "git://github.com/rspec/rspec.git"
  gem "rspec-core",         :git => "git://github.com/rspec/rspec-core.git"
  gem "rspec-expectations", :git => "git://github.com/rspec/rspec-expectations.git"
  gem "rspec-mocks",        :git => "git://github.com/rspec/rspec-mocks.git"
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
  gem 'spork', '0.9.0.rc4'
  gem 'rb-fsevent'
  gem 'growl'
  gem 'guard'
  # gem 'guard-bundler'
  gem 'guard-pow'
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'rspec-instafail'
  gem 'livereload'
  gem 'guard-livereload'

  gem 'shoulda'
  gem 'capybara', :git => 'git://github.com/thibaudgg/capybara.git'
  gem 'webmock'
  gem 'vcr'

  gem 'database_cleaner'
  gem 'factory_girl_rails', :require => false # loaded in spec_helper Spork.each_run
end
