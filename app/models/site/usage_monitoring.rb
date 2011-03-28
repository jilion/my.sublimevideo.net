module Site::UsageMonitoring

  # ================================
  # = Site class methods extension =
  # ================================

  # Recurring task
  def self.delay_monitor_sites_usages(interval = 1.day)
    unless Delayed::Job.already_delayed?('%Site::UsageMonitoring%monitor_sites_usages%')
      delay(:priority => 50, :run_at => (Time.now.utc.tomorrow.midnight + 1.hour)).monitor_sites_usages
    end
  end

  def self.monitor_sites_usages
    delay_monitor_sites_usages

    Site.active.in_paid_plan.where(:first_plan_upgrade_required_alert_sent_at => nil).each do |site|
      if site.current_monthly_billable_usage > site.plan.player_hits
        if site.days_since(site.first_paid_plan_started_at) >= 20 && site.percentage_of_days_over_daily_limit(60) > 0.5
          site.touch(:first_plan_upgrade_required_alert_sent_at)
          # UsageMonitoringMailer.plan_upgrade_required(site).deliver! # TODO BEFORE April 17
        elsif site.plan_player_hits_reached_notification_sent_at.nil? || site.plan_player_hits_reached_notification_sent_at < site.plan_month_cycle_started_at
          site.touch(:plan_player_hits_reached_notification_sent_at)
          UsageMonitoringMailer.plan_player_hits_reached(site).deliver!
        end
      end
    end

    # Sent daily "plan upgrade required" alert
    # Site.active.in_paid_plan.where(:first_plan_upgrade_required_alert_sent_at.ne => nil).each do |site|
    #   UsageMonitoringMailer.plan_upgrade_required(site).deliver!
    # end
  end

end

# == Schema Information
#
# Table name: sites
#
#  plan_player_hits_reached_notification_sent_at :datetime
#  first_plan_upgrade_required_alert_sent_at :datetime
#
