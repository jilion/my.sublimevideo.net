require 'scheduler'

namespace :scheduler do

  desc "Supervise job queues"
  task :supervise => :environment do
    Scheduler.supervise_queues
  end

  desc "Schedule all daily recurring jobs."
  task :daily => :environment do
    Scheduler.schedule_daily_tasks
  end

  desc "Schedule all hourly recurring jobs."
  task :hourly => :environment do
    Scheduler.schedule_hourly_tasks
  end

  desc "Schedule logs recurring download & parsing for the next 10 minures"
  task :frequent => :environment do
    Scheduler.schedule_frequent_tasks
  end

end
