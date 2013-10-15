ignore /public/
notification :gntp

group :frontend do

  guard :pow do
    watch(%r{^\.pow(rc|env)})
    watch('config/boot.rb')
    watch('config/application.rb')
    watch('config/environment.rb')
    watch(%r{^config/environments/.+\.rb})
    watch(%r{^config/initializers/.+\.rb})
  end

  guard :livereload, host: 'my.sublimevideo.dev' do
    watch(%r{app/views/.+\.(erb|haml)})
    watch(%r{app/(exhibits|helpers|presenters)/.+\.rb})
    # watch(%r{public/.+\.(css|js|html)})
    watch(%r{(app|vendor)/assets/\w+/(.+\.(css|js|html)).*})  { |m| "/assets/#{m[2]}" }
    watch(%r{app/assets/\w+/(.+)\.hamlc.*})                   { |m| "/assets/#{m[1]}.js" }
    watch(%r{config/locales/.+\.yml})
  end

  guard :teaspoon do
    watch(%r{app/assets/javascripts/(.+)\.(js\.coffee|js)}) { |m| "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
    watch(%r{spec/javascripts/(.+)_spec\.(js\.coffee|js)})  { |m| "spec/javascripts/#{m[1]}_spec.#{m[2]}" }
    watch('spec/javascripts/spec_helper.js.coffee')         { "spec/javascripts" }
  end

end

group :backend do
  guard :shell do
    watch 'config/routes.rb' do
      Thread.new do
        routes = `bundle exec rake routes`
        if $?.success?
          File.open('doc/routes.txt', 'w') do |f|
            f << routes
          end
          n 'Updated routes.txt', 'Computed new routes', :success
        else
          n "'bundle exec rake routes failed'", 'Error computing routes!', :failed
        end
      end
    end
  end

  guard :rspec do
    watch('app/controllers/application_controller.rb')                         { "spec/controllers" }
    watch('config/routes.rb')                                                  { "spec/routing" }
    watch(%r{^spec/support/(controllers|mailers|models|presenters|features|routing)_helpers\.rb}) { |m| "spec/#{m[1]}" }
    watch(%r{^spec/.+/.+_spec\.rb})

    watch(%r{^app/controllers/(.+)_(controller)\.rb})                          { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/requests/#{m[1]}_spec.rb", "spec/features/#{m[1]}_spec.rb"] }
    watch(%r{^db/migrate/(.+)\.rb})                                            { |m| "spec/migrations/#{m[1]}_spec.rb" }
    watch(%r{^app/(.+)\.rb})                                                   { |m| "spec/#{m[1]}_spec.rb" }
    watch(%r{^lib/(.+)\.rb})                                                   { |m| "spec/lib/#{m[1]}_spec.rb" }
  end
end
