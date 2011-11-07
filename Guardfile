# notification :gntp

group :frontend do

  guard :pow do
    watch('.rvmrc')
    watch(%r{^\.pow(rc|env)$})
    # watch('Gemfile.lock')
    watch('config/boot.rb')
    watch('config/application.rb')
    watch('config/environment.rb')
    watch(%r{^config/environments/.+\.rb})
    watch(%r{^config/initializers/.+\.rb})
  end

  # guard 'coffeescript', :input => 'app/assets/javascripts', :noop => true, :hide_success => true

  guard :livereload, host: 'my.sublimevideo.net.dev' do
    watch(%r{^app/.+\.(erb|haml|js|css|scss|coffee|eco|png|gif|jpg)})
    watch(%r{^app/helpers/.+\.rb})
    watch(%r{^public/.+\.html})
    watch(%r{^config/locales/.+\.yml})
  end

  guard :jasmine, :server => :none, :jasmine_url => 'http://my.sublimevideo.net.dev/jasmine', :all_on_start => false do
    watch(%r{app/assets/javascripts/(.+)\.(js\.coffee|js)}) { |m| "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
    watch(%r{spec/javascripts/(.+)_spec\.(js\.coffee|js)})  { |m| "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
    watch(%r{spec/javascripts/spec\.(js\.coffee|js)})       { "spec/javascripts" }
  end

end

group :backend do

  guard :spork, :wait => 70 do
    watch('Gemfile')
    # watch('Gemfile.lock')
    watch('config/boot.rb')
    watch('config/application.rb')
    watch('config/environment.rb')
    watch(%r{^config/environments/.+\.rb})
    watch(%r{^config/initializers/.+\.rb})
    watch('spec/spec_helper.rb')
  end

  guard :rspec, :version => 2, :cli => "--color --drb", :all_after_pass => false, :all_on_start => false, :keep_failed => false do
    watch('spec/spec_helper.rb')                                               { "spec" }
    watch('app/controllers/application_controller.rb')                         { "spec/controllers" }
    watch('config/routes.rb')                                                  { "spec/routing" }
    watch(%r{^spec/support/(requests|controllers|mailers|models)_helpers\.rb}) { |m| "spec/#{m[1]}" }
    watch(%r{^spec/.+_spec\.rb})

    watch(%r{^app/controllers/(.+)_(controller)\.rb})                          { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/requests/#{m[1]}_spec.rb"] }

    watch(%r{^app/(.+)\.rb})                                                   { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^lib/(.+)\.rb})                                                   { |m| "spec/lib/#{m[1]}_spec.rb" }
  end

end

# guard :yard do
#   watch(%r{^app/.+\.rb$})
#   watch(%r{^lib/.+\.rb$})
# end
