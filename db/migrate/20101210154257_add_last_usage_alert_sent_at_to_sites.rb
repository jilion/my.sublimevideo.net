class AddLastUsageAlertSentAtToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :plan_player_hits_reached_alert_sent_at, :datetime
    add_column :sites, :next_plan_recommended_alert_sent_at, :datetime
  end
  
  def self.down
    remove_column :sites, :plan_player_hits_reached_alert_sent_at
    remove_column :sites, :next_plan_recommended_alert_sent_at
  end
end