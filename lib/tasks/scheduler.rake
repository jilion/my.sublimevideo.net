namespace :scheduler do

  desc "Supervise if all recurring jobs are scheduled"
  task :supervise_jobs => :environment do
    RecurringJob.supervise
  end

end