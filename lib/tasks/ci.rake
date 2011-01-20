namespace :ci do
  desc "Run all required tasks to perform our build"
  task :build => :environment do
    puts "foo!!"
    system "pwd"
    system "bundle install"
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:test:prepare"].invoke
    Rake::Task["db:seed"].invoke
    Rake::Task["spec"].invoke
  end
end
