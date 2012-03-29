namespace :scheduler do

  desc "Supervise if all recurring jobs are scheduled"
  task :supervise_jobs => :environment do
    RecurringJob.supervise
  end

  desc "Launch all recurring jobs if they are not already scheduled"
  task :launch_all => :environment do
    RecurringJob.launch_all
  end

end