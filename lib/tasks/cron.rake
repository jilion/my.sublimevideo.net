desc "Heroku cron job"
task :cron => :environment do
  Log.delay_new_logs_download
  User::Trial.delay_supervise_users
  User::LimitAlert.delay_send_limit_alerts
end