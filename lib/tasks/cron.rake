desc "Heroku cron job"
task :cron => :environment do
  RecurringJob.supervise
end