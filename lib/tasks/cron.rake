desc "Heroku cron job"
task :cron => :environment do
  require 'app/models/log/amazon/s3' # not sure why, but needed!
  
  Log.delay_fetch_and_create_new_logs
  User::CreditCard.delay_send_credit_card_expiration
  User::Trial.delay_supervise_users
  User::LimitAlert.delay_send_limit_alerts
end