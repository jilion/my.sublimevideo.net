source 'https://rubygems.org'
source 'https://8dezqz7z7HWea9vtaFwg:@gem.fury.io/me/' # thibaud@jilion.com account

ruby '2.0.0'

gem 'rails', '4.0.1'
gem 'sprockets-rails', github: 'rails/sprockets-rails'

gem 'sublime_video_layout', '~> 2.6' # hosted on gemfury
gem 'sublime_video_private_api', '~> 1.6' # hosted on gemfury

# Databases
gem 'pg'
gem 'mongoid', github: 'mongoid'
gem 'moped', github: 'mongoid/moped'

# Views
gem 'haml'
gem 'rabl'
gem 'coffee-rails'
gem 'kaminari', github: 'kolodovskyy/kaminari' # https://github.com/amatsuda/kaminari/pull/433
gem 'liquid'
gem 'hpricot'
gem 'display_case'
gem 'rails_autolink'
# until > 1.4.0 is released
gem 'premailer-rails', github: 'fphilipe/premailer-rails'
gem 'turbolinks'
gem 'google-analytics-turbolinks'

# Admin charts
gem 'groupdate'
gem 'chartkick'

# Auth / invitations
gem 'devise', '~> 3.0.3'
gem 'devise_invitable'
gem 'devise-async'

# API
gem 'oauth'
gem 'oauth-plugin', github: 'pelle/oauth-plugin' # Rails 4 support

# Internals
gem 'sidekiq'

gem 'rescue_me'
gem 'libxml-ruby', require: 'libxml'
gem 'oj' # Faster JSON
gem 'kgio' # Faster IO

gem 'state_machine'
gem 'paper_trail', '3.0.0.beta1'
gem 'uniquify'
gem 'acts-as-taggable-on', github: 'mbleigh/acts-as-taggable-on' # Need > 2.4.1
gem 'paranoia'

gem 'responders'
gem 'has_scope'

gem 'fog'
gem 'unf' # encoding for fog
gem 'carrierwave', require: ['carrierwave', 'carrierwave/processing/mime_types']
gem 'cocaine'


gem 'activemerchant'

gem 'public_suffix'

gem 'rubyzip'
gem 'mime-types'
gem 'countries'
gem 'country_select'
gem 'snail'
gem 'PageRankr'
gem 'twitter'
gem 'array_stats'
gem 'createsend' # Campaign Monitor
gem 'http_content_type'

# Monitoring
gem 'rack-status'
gem 'honeybadger'
gem 'prowl'
gem 'tinder' # Campfire
gem 'librato-rails'

# Stats
gem 'crack'
gem 'pusher'
gem 'redis'

# Tickets
gem 'zendesk_api'

# App
gem 'solve'

gem 'execjs'
gem 'backbone-rails'
gem 'haml_coffee_assets'
gem 'sass-rails'
gem 'chosen-rails', github: 'jilion/chosen-rails'
gem 'compass-rails', github: 'Compass/compass-rails'
gem 'uglifier'

group :production do
  gem 'rack-google-analytics', github: 'leehambley/rack-google-analytics'
end

group :staging, :production do
  gem 'unicorn', require: false
  gem 'rails_12factor'
  gem 'rack-ssl-enforcer'
  gem 'memcachier'
  gem 'dalli'
  gem 'rack-cache'
  gem 'lograge'
  gem 'newrelic_rpm'
  gem 'newrelic-redis'
  gem 'newrelic_moped'
end

group :development do
  gem 'rack-livereload'
  gem 'launchy'
  gem 'bullet'
  gem 'annotate', require: false

  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'letter_opener'
  gem 'powder', require: false
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'timecop'

  # Javascript test
  gem 'teaspoon'

  # Rails routes view
  gem 'sextant'

  # Guard
  gem 'ruby_gntp', require: false
  gem 'guard-pow', require: false
  gem 'guard-livereload', require: false
  gem 'guard-rspec', require: false
  gem 'guard-shell', require: false
  gem 'guard-teaspoon', require: false
end

group :test do
  gem 'shoulda-matchers'
  gem 'ffaker'
  gem 'capybara'
  gem 'capybara-email'
  gem 'poltergeist'
  gem 'show_me_the_cookies'
  gem 'webmock'
  gem 'typhoeus'
  gem 'vcr'
  gem 'codeclimate-test-reporter', require: false

  gem 'database_cleaner'
  gem 'factory_girl'
  gem 'factory_girl_rails' # loaded in spec_helper Spork.each_run
end
