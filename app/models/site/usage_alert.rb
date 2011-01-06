# == Schema Information
#
# Table name: sites
#
#  plan_player_hits_reached_alert_sent_at :datetime
#  next_plan_recommended_alert_sent_at :datetime
#

module Site::UsageAlert

  # ================================
  # = User class methods extension =
  # ================================

  def self.delay_send_usage_alerts(interval = 1.hour)
    unless Delayed::Job.already_delayed?('%Site::UsageAlert%send_usage_alerts%')
      delay(:run_at => interval.from_now).send_usage_alerts
    end
  end

  def self.send_usage_alerts
    delay_send_usage_alerts
    send_plan_player_hits_reached_alerts
    send_next_plan_recommended_alerts
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

  def self.send_next_plan_recommended_alerts
    invoice = Invoice.new(:started_at => TimeUtil.current_month.first, :ended_at => TimeUtil.current_month.second)
    Site.plan_player_hits_reached_alerted_this_month.next_plan_recommended_alert_sent_at_not_alerted_this_month.each do |site|
      if site.plan.next_plan.present? && (site.plan.price + InvoiceItem::Overage.build(:invoice => invoice, :site => site).amount) > site.plan.next_plan.price
        Site.transaction do
          site.touch(:next_plan_recommended_alert_sent_at)
          UsageAlertMailer.next_plan_recommended(site).deliver!
        end
      end
    end
  end

end
