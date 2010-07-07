desc "Heroku cron job"
task :cron => :environment do
  
  RecurringJob.launch_all
  
  # need to ask a superviser now
  
end