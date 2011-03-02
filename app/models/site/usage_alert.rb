# == Schema Information
#
# Table name: sites
#
#  plan_player_hits_reached_alert_sent_at :datetime
#

module Site::UsageAlert

  # ================================
  # = User class methods extension =
  # ================================

  # Recurring task
  def self.delay_send_usage_alerts(interval = 1.hour)
    unless Delayed::Job.already_delayed?('%Site::UsageAlert%send_usage_alerts%')
      delay(:run_at => interval.from_now).send_usage_alerts
    end
  end

  def self.send_usage_alerts
    delay_send_usage_alerts
    send_plan_player_hits_reached_alerts
  end

private

  def self.send_plan_player_hits_reached_alerts
    Site.billable(*TimeUtil.current_month).plan_player_hits_reached_not_alerted_this_month.each do |site|
      site_usages = site.usages.between(*TimeUtil.current_month).only(:main_player_hits, :main_player_hits_cached, :extra_player_hits, :extra_player_hits_cached)
      usage = site_usages.inject(0) { |sum, u| sum += u.main_player_hits + u.main_player_hits_cached + u.extra_player_hits + u.extra_player_hits_cached }

      if usage > site.plan.player_hits
        Site.transaction do
          site.touch(:plan_player_hits_reached_alert_sent_at)
          UsageAlertMailer.plan_player_hits_reached(site).deliver!
        end
      end
    end
  end

end
