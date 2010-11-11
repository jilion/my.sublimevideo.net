guard 'bundler' do
  watch('^Gemfile')
end

guard 'passenger' do
  # watch('^lib/.*\.rb$')
  watch('^config/application.rb$')
  watch('^config/environment.rb$')
  watch('^config/environments/.*\.rb$')
  watch('^config/initializers/.*\.rb$')
end

guard 'spork' do
  watch('^config/application.rb$')
  watch('^config/environment.rb$')
  watch('^config/environments/.*\.rb$')
  watch('^config/initializers/.*\.rb$')
  watch('^spec/spec_helper.rb')
end

# guard 'livereload' do
#   watch('^app/.+\.(erb|haml)$')
#   watch('^app/helpers/.+\.rb$')
#   watch('^/public/.+\.(css|js|html)$')
#   watch('^config/locales/.+\.ym$')
# end

guard 'rspec', :version => 2, :drb => true, :bundler => false, :formatter => "instafail", :fail_fast => true do
  watch('^spec/spec_helper.rb')                       { "spec" }
  watch('^spec/factories.rb')                         { "spec/models" }
  watch('^app/controllers/application_controller.rb') { "spec/controllers" }
  watch('^spec/support/controller_helpers.rb')        { "spec/controllers" }
  watch('^spec/support/acceptance_helpers.rb')        { "spec/acceptance" }
  watch('^config/routes.rb')                          { "spec/routing" }
  watch('^spec/(.*)_spec.rb')
  watch('^app/(.*)\.rb')                              { |m| "spec/#{m[1]}_spec.rb" }
  watch('^lib/(.*)\.rb')                              { |m| "spec/lib/#{m[1]}_spec.rb" }
end