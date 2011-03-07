group 'frontend' do

  guard 'passenger', :ping => true do
    watch('config/application.rb')
    watch('config/environment.rb')
    watch(%r{^config/environments/.+\.rb})
    watch(%r{^config/initializers/.+\.rb})
  end

  guard 'livereload', :apply_js_live => false do
    watch(%r{^app/.+\.(erb|haml)})
    watch(%r{^app/helpers/.+\.rb})
    watch(%r{^public/javascripts/.+\.js})
    watch(%r{^public/stylesheets/.+\.css})
    watch(%r{^public/.+\.html})
    watch(%r{^config/locales/.+\.yml})
  end

end

group 'backend' do

  guard 'bundler' do
    watch('Gemfile')
  end

  guard 'spork', :wait => 50 do
    watch('Gemfile')
    watch('config/application.rb')
    watch('config/environment.rb')
    watch(%r{^config/environments/.+\.rb})
    watch(%r{^config/initializers/.+\.rb})
    watch('spec/spec_helper.rb')
  end

  guard 'rspec', :version => 2, :cli => "--color --drb", :bundler => false do
    watch('spec/spec_helper.rb')                                  { "spec" }
    watch('app/controllers/application_controller.rb')            { "spec/controllers" }
    watch('config/routes.rb')                                     { "spec/routing" }
    watch(%r{^spec/support/(controllers|acceptance)_helpers\.rb}) { |m| "spec/#{m[1]}" }
    watch(%r{^spec/.+_spec\.rb})

    watch(%r{^app/controllers/(.+)_(controller)\.rb}) { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }

    watch(%r{^app/(.+)\.rb}) { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^lib/(.+)\.rb}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  end

end
