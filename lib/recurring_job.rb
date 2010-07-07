module RecurringJob
  class << self
    
    def launch_all
      Log.delay_fetch_and_create_new_logs
      User::CreditCard.delay_send_credit_card_expiration
      User::Trial.delay_supervise_users
      User::LimitAlert.delay_send_limit_alerts
    end
    
    def supervise
      # TODO
    end
    
  end
end