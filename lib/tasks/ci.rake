namespace :ci do
  desc "Run all required tasks to perform our build"
  task :build do
    RAILS_ENV = ENV['RAILS_ENV'] = 'test'
    sh "bundle --quiet"
    Rake::Task["db:migrate --trace"].invoke
    Rake::Task["db:test:prepare --trace"].invoke
    Rake::Task["db:seed --trace"].invoke
    SPORK = ENV['SPORK'] = 'false'
    Rake::Task["spec --trace"].invoke
  end
end
