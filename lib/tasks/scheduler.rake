require 'recurring_job'

namespace :scheduler do

  desc "Supervise job queues"
  task :supervise => :environment do
    RecurringJob.supervise_queues
  end

  desc "Schedule all daily recurring jobs."
  task :daily => :environment do
    RecurringJob.schedule_daily_tasks
  end

  desc "Schedule all hourly recurring jobs."
  task :hourly => :environment do
    RecurringJob.schedule_hourly_tasks
  end

  desc "Schedule logs recurring download & parsing for the next 10 minures"
  task :frequent => :environment do
    RecurringJob.schedule_frequent_tasks
  end

end
