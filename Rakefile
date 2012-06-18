# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Dir[Rails.root.join('lib/*.rb')].each { |f| require f }
Dir[Rails.root.join('lib/campaign_monitor/*.rb')].each { |f| require f }
Dir[Rails.root.join('lib/custom/**/*.rb')].each { |f| require f }
Dir[Rails.root.join('lib/one_time/*.rb')].each { |f| require f }
Dir[Rails.root.join('lib/responders/*.rb')].each { |f| require f }
Dir[Rails.root.join('lib/validators/*.rb')].each { |f| require f }
Dir[Rails.root.join('lib/zendesk/*.rb')].each { |f| require f }

require 'rake'
require 'delayed/tasks'

if %w[development test].include?(Rails.env)
  # Jasmine
  require 'guard/jasmine/task'
  Guard::JasmineTask.new do |task|
    task.options = '-t 20000 -e development'
  end
end

# Annotate settings
ENV['position_in_class'] = "before"
ENV['show_indexes']      = "true"

MySublimeVideo::Application.load_tasks
