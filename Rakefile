# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

if %w[development test].include?(Rails.env)
  # Jasmine
  require 'guard/jasmine/task'
  Guard::JasmineTask.new do |task|
    task.options = '-t 20000 -e development'
  end
end

MySublimeVideo::Application.load_tasks
