class RemoveBetaFields < ActiveRecord::Migration
  def self.up
    remove_column :users, :trial_ended_at
    remove_column :users, :trial_usage_information_email_sent_at
    remove_column :users, :trial_usage_warning_email_sent_at
    remove_column :users, :limit_alert_amount
    remove_column :users, :limit_alert_email_sent_at
  end
  
  def self.down
  end
end
