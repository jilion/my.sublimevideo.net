# Doesn't seem to work...
# guard 'ego' do
#   watch('Guardfile')
# end

guard 'bundler' do
  watch('Gemfile')
end

guard 'passenger', :ping => true do
  watch('config/application\.rb')
  watch('config/environment\.rb')
  watch(%r|config/environments/.*\.rb|)
  watch(%r|config/initializers/.*\.rb|)
end

guard 'spork', :wait => 40 do
  watch('config/application\.rb')
  watch('config/environment\.rb')
  watch(%r|config/environments/.*\.rb|)
  watch(%r|config/initializers/.*\.rb|)
  watch('spec/spec_helper\.rb')
end

guard 'rspec', :version => 2, :drb => true, :bundler => false, :fail_fast => false, :formatter => "instafail" do
  watch('spec/spec_helper\.rb')                               { "spec" }
  watch('app/controllers/application_controller\.rb')         { "spec/controllers" }
  watch('config/routes\.rb')                                  { "spec/routing" }
  watch(%r{spec/support/(controller|acceptance)_helpers\.rb}) { |m| "spec/#{m[1]}" }
  watch(%r|spec/.*_spec\.rb|)                                  
  
  watch(%r|app/controllers/(.*)_controller\.rb|)              { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/controllers/#{m[1]}_controller_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  
  watch(%r|app/(.*)\.rb|)                                     { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r|lib/(.*)\.rb|)                                     { |m| "spec/lib/#{m[1]}_spec.rb" }
  
  # temporary watcher
  # watch(%|site_observer(_spec)?\.rb|) {
  #   ["spec/models/site_observer_spec.rb",
  #    "spec/models/invoice_item_spec.rb", "spec/models/invoice_item/addon_spec.rb",
  #    "spec/models/invoice_item/overage_spec.rb", "spec/models/invoice_item/plan_spec.rb"]
  #  }
end

# guard 'livereload' do
#   watch(%r{app/.+\.(erb|haml)})
#   watch(%r|app/helpers/.+\.rb|)
#   watch(%r|public/javascripts/.+\.js|)
#   watch(%r|public/stylesheets/.+\.css|)
#   watch(%r|public/.+\.html|)
#   watch(%r|config/locales/.+\.yml|)
# end