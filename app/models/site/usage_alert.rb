# == Schema Information
#
# Table name: sites
#
#  last_usage_alert_sent_at :datetime
#

module Site::UsageAlert
  
  # ================================
  # = User class methods extension =
  # ================================
  
  def self.delay_send_usage_alert(interval = 1.hour)
    unless Delayed::Job.already_delayed?('%Site::UsageAlert%send_usage_alert%')
      delay(:run_at => interval.from_now).send_usage_alert
    end
  end
  
  def self.send_usage_alert
    delay_send_usage_alert
    Site.billable(*TimeUtil.current_month).not_alerted_this_month.each do |site|
      site_usages = site.usages.between(*TimeUtil.current_month).only(:main_player_hits, :main_player_hits_cached, :extra_player_hits, :extra_player_hits_cached)
      usage = site_usages.inject(0) { |sum, u| sum += u.main_player_hits + u.main_player_hits_cached + u.extra_player_hits + u.extra_player_hits_cached }
      
      if usage > site.plan.player_hits
        Site.transaction do
          site.touch(:last_usage_alert_sent_at)
          UsageAlertMailer.limit_reached(site).deliver!
        end
      end
    end
  end
  
end