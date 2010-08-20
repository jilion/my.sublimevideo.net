module RecurringJob
  
  logs_tasks = [
    '%Log::Voxcast%fetch_download_and_create_new_logs%',
    '%Log::Amazon::S3::Player%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Loaders%fetch_and_create_new_logs%',
    '%Log::Amazon::S3::Licenses%fetch_and_create_new_logs%'
  ]
  
  NAMES = if MySublimeVideo::Release.public?
    [
      '%User::LimitAlert%send_limit_alerts%',
      '%User::CreditCard%send_credit_card_expiration%',
      '%User::Trial%supervise_users%'
    ] + logs_tasks
  else
    logs_tasks
  end
  
  class << self
    
    def launch_all
      Log.delay_fetch_and_create_new_logs
      if MySublimeVideo::Release.public?
        User::CreditCard.delay_send_credit_card_expiration
        User::Trial.delay_supervise_users
        User::LimitAlert.delay_send_limit_alerts
      end
    end
    
    def supervise
      unless all_delayed?
        HoptoadNotifier.notify(:error_message => "WARNING!!! All recurring jobs are not delayed, please investigate quickly!")
      end
    end
    
  private
    
    def all_delayed?
      NAMES.all? { |name| Delayed::Job.already_delayed?(name) }
    end
    
  end
end