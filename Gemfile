source 'http://rubygems.org'

gem 'rails', '3.0.0.beta3'
gem 'heroku'
gem 'i18n'
gem 'haml', '>= 3.0.0'
gem 'devise', '>= 1.1.rc1'
gem 'state_machine'
gem 'responders'
gem 'uniquify'

gem 'aws'
gem 'carrierwave', :git => 'http://github.com/jnicklas/carrierwave.git'

gem 'jammit',       :git => 'git://github.com/railsjedi/jammit.git'

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
  
  gem 'rspec',        '>= 2.0.0.beta.8'
  gem 'rspec-rails', :git => 'http://github.com/rspec/rspec-rails.git', :ref => "d2fb9f35c7867225cd68758152f51dd3d1152a09"
  
  gem 'factory_girl', :git => 'git://github.com/danielb2/factory_girl'
  
  gem 'steak', '0.4.0.a4'
  gem "capybara"
  # gem "capybara-envjs"
  
  gem 'email_spec'
  gem "launchy"
  gem "ruby-debug"
end

group :production do
  gem 'pg'  
end