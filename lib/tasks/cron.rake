desc "Heroku cron job"
task :cron => :environment do
  Log.delay_new_logs_download
end
