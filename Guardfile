guard 'rspec', :version => 2 do
  watch('^spec/(.*)_spec.rb')
  watch('^lib/(.*).rb')                               { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')                        { "spec" }
  watch('^app/(.*)\.rb')                              { |m| "spec/#{m[1]}_spec.rb" }
  watch('^config/routes.rb')                          { |m| "spec/routing" }
  watch('^spec/factories.rb')                         { |m| "spec/models" }
  watch('^app/controllers/application_controller.rb') { |m| "spec/controllers" }
end
