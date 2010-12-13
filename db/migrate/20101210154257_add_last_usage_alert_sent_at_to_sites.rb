class AddLastUsageAlertSentAtToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :last_usage_alert_sent_at, :datetime
  end
  
  def self.down
    remove_column :sites, :last_usage_alert_sent_at
  end
end