# == Schema Information
#
# Table name: users
#
#  limit_alert_amount                    :integer         default(0)
#  limit_alert_email_sent_at             :datetime
#

module User::LimitAlert
  
  def self.amounts_options
    [2000, 5000, 10000, 20000, 50000] # in cents
  end
  
  def self.delay_send_limit_alerts(minutes = 10.minutes)
    unless Delayed::Job.already_delayed?('%send_limit_alerts%')
      delay(:priority => 30, :run_at => minutes.from_now).send_limit_alerts
    end
  end
  
  def self.send_limit_alerts
    delay_send_limit_alerts
    User.limit_alertable.includes(:invoices, :sites, :videos).each do |user|
      if user.limit_alert_amount_exceeded?
        user.deliver_alert_limit_email
      end
    end
  end
  
  # ===================================
  # = User instance methods extension =
  # ===================================
  
  def limit_alert_sent?
    limit_alert_email_sent_at.present?
  end
  
  def limit_alert_amount_exceeded?
    Invoice.current(self).amount > limit_alert_amount
  end
  
  def deliver_alert_limit_email
    transaction do
      touch(:limit_alert_email_sent_at)
      LimitAlertMailer.limit_exceeded(self).deliver!
    end
  end
  
  def clear_limit_alert_email_sent_at_when_limit_alert_amount_is_augmented
    if limit_alert_amount_changed? && limit_alert_amount_was < limit_alert_amount
      self.limit_alert_email_sent_at = nil
    end
  end
  
end