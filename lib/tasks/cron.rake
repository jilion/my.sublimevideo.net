desc "Heroku cron job"
task :cron => :environment do
  Log.delay_fetch_and_create_new_logs
  User::Trial.delay_supervise_users
  User::LimitAlert.delay_send_limit_alerts
end