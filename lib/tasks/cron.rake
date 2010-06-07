desc "Heroku cron job"
task :cron => :environment do
  Log.delay_new_logs_download
  Trial.delay_supervise_users
end
