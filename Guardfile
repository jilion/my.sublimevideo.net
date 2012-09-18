# notification :gntp
# interactor :coolline

group :frontend do

  guard :pow do
    watch('.rvmrc')
    watch(%r{^\.pow(rc|env)$})
    watch('config/boot.rb')
    watch('config/application.rb')
    watch('config/environment.rb')
    watch(%r{^config/environments/.+\.rb})
    watch(%r{^config/initializers/.+\.rb})
  end

  guard :livereload, host: 'my.sublimevideo.dev' do
    watch(%r{app/views/.+\.(erb|haml)})
    watch(%r{app/helpers/.+\.rb})
    # watch(%r{public/.+\.(css|js|html)})
    watch(%r{(app|vendor)/assets/\w+/(.+\.(css|js|html)).*})  { |m| "/assets/#{m[2]}" }
    watch(%r{app/assets/\w+/(.+)\.hamlc.*})                   { |m| "/assets/#{m[1]}.js" }
    watch(%r{config/locales/.+\.yml})
  end

  guard :jasmine, server: :none, jasmine_url: 'http://my.sublimevideo.dev/jasmine', all_on_start: false, timeout: 20000 do
    watch(%r{app/assets/javascripts/(.+)\.(js\.coffee|js)}) { |m| "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
    watch(%r{spec/javascripts/(.+)_spec\.(js\.coffee|js)})  { |m| "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
    watch(%r{spec/javascripts/spec\.(js\.coffee|js)})       { "spec/javascripts" }
  end

end

group :backend do

  guard :rspec, bundler: false, version: 2, all_after_pass: false, all_on_start: false, keep_failed: false do
    watch('app/controllers/application_controller.rb')                         { "spec/controllers" }
    watch('config/routes.rb')                                                  { "spec/routings" }
    watch(%r{^spec/support/(controllers|mailers|models|requests|routings)_helpers\.rb}) { |m| "spec/#{m[1]}" }
    watch(%r{^spec/(controllers|helpers|lib|mailers|models|requests|routings|uploaders)/.+_spec\.rb})

    watch(%r{^app/controllers/(.+)_(controller)\.rb})                          { |m| ["spec/routings/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/requests/#{m[1]}_spec.rb"] }

    watch(%r{^app/(.+)\.rb})                                                   { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^lib/(.+)\.rb})                                                   { |m| "spec/lib/#{m[1]}_spec.rb" }
  end

end
