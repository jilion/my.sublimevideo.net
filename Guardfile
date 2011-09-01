group :frontend do

  guard :pow do
    watch('.rvmrc')
    watch(%r{^\.pow(rc|env)$})
    # watch('Gemfile.lock')
    watch(%r{^config/.+\.rb$})
  end

  guard :livereload do
    watch(%r{^app/.+\.(erb|haml|js|css|scss|coffee|eco|png|gif|jpg)})
    watch(%r{^app/helpers/.+\.rb})
    watch(%r{^public/.+\.html})
    watch(%r{^config/locales/.+\.yml})
  end

end

group :backend do

  guard 'spork', :wait => 50 do
    watch('Gemfile')
    watch('Gemfile.lock')
    watch('config/application.rb')
    watch('config/environment.rb')
    watch(%r{^config/environments/.+\.rb})
    watch(%r{^config/initializers/.+\.rb})
    watch('spec/spec_helper.rb')
  end

  guard :rspec, :version => 2, :cli => "--color --drb -f Fuubar", :all_after_pass => false, :all_on_start => false, :keep_failed => false do
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

group :jasmine do

  guard 'rails-assets' do
    watch(%r{^app/assets/.+$})
    watch('config/application.rb')
  end

  guard 'jasmine-headless-webkit', :valid_extensions => ['coffee'] do
    watch(%r{^public/assets/.*\.js})
    watch(%r{^spec/javascripts/helpers/*})
    watch(%r{^spec/javascripts/support/*})
    watch(%r{^spec/javascripts/(.*)_spec.coffee})
  end

end
