module SiteModules::UsageMonitoring

  # ================================
  # = Site class methods extension =
  # ================================

  # Recurring task
  def self.delay_monitor_sites_usages(interval = 1.day)
    unless Delayed::Job.already_delayed?('%SiteModules::UsageMonitoring%monitor_sites_usages%')
      delay(:priority => 50, :run_at => (Time.now.utc.tomorrow.midnight + 1.hour)).monitor_sites_usages
    end
  end

  def self.monitor_sites_usages
    delay_monitor_sites_usages

    Site.paid_plan.where(:first_plan_upgrade_required_alert_sent_at => nil).each do |site|
      if site.current_monthly_billable_usages.sum > site.plan.video_views
        if site.days_since(site.first_paid_plan_started_at) >= 20 && site.percentage_of_days_over_daily_limit(60) > 0.5
          # site.touch(:first_plan_upgrade_required_alert_sent_at)
          # My::UsageMonitoringMailer.plan_upgrade_required(site).deliver!
        elsif site.overusage_notification_sent_at.nil? || site.overusage_notification_sent_at < site.plan_month_cycle_started_at
          site.touch(:overusage_notification_sent_at)
          My::UsageMonitoringMailer.plan_overused(site).deliver!
        end
      end
    end

    # Sent daily "plan upgrade required" alert
    # Site.paid_plan.where(:first_plan_upgrade_required_alert_sent_at.not_eq => nil).each do |site|
    #   My::UsageMonitoringMailer.plan_upgrade_required(site).deliver!
    # end
  end

end

# == Schema Information
#
# Table name: sites
#
#  overusage_notification_sent_at :datetime
#  first_plan_upgrade_required_alert_sent_at :datetime
#
