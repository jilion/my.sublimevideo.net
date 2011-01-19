namespace :ci do
  desc "Run all required tasks to perform our build"
  task :build => :environment do
    sh "bundle --quiet"
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:test:prepare "].invoke
    Rake::Task["db:seed"].invoke
    # SPORK = ENV['SPORK'] = 'false'
    Rake::Task["spec"].invoke
  end
end
