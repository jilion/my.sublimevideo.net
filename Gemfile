source 'http://rubygems.org'

gem 'rails', '3.0.0.beta3'
gem 'heroku'

gem 'i18n'
gem 'haml'
gem 'devise',       '>= 1.1.rc1'
gem 'state_machine'
gem 'jammit',       :git => 'git://github.com/railsjedi/jammit.git'

group :development do
  # bundler requires these gems in development
  gem 'sqlite3-ruby', :require => 'sqlite3'
  gem 'annotate'
  
  # Ruby console
  gem 'looksee'
  gem 'wirble'
end

group :test do
  gem 'sqlite3-ruby', :require => 'sqlite3'
  
  gem 'rspec',        '>= 2.0.0.beta.8'
  gem 'rspec-rails',  '>= 2.0.0.beta.8'
  
  gem 'factory_girl', :git => 'git://github.com/danielb2/factory_girl'
end

group :production do
  gem 'pg'
end