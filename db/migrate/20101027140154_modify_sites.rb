class ModifySites < ActiveRecord::Migration
  def self.up
    add_column :sites, :extra_hostnames, :string
    add_column :sites, :plan_id, :integer
    add_column :sites, :pending_plan_id, :integer
    add_column :sites, :next_cycle_plan_id, :integer
    add_column :sites, :cdn_up_to_date, :boolean, default: false
    add_column :sites, :first_paid_plan_started_at, :datetime
    add_column :sites, :plan_started_at, :datetime
    add_column :sites, :plan_cycle_started_at, :datetime
    add_column :sites, :plan_cycle_ended_at, :datetime
    add_column :sites, :pending_plan_started_at, :datetime
    add_column :sites, :pending_plan_cycle_started_at, :datetime
    add_column :sites, :pending_plan_cycle_ended_at, :datetime
    add_column :sites, :plan_player_hits_reached_notification_sent_at, :datetime
    add_column :sites, :first_plan_upgrade_required_alert_sent_at, :datetime
    add_column :sites, :refunded_at, :datetime

    add_column :sites, :last_30_days_main_player_hits_total_count, :integer, default: 0
    add_column :sites, :last_30_days_extra_player_hits_total_count, :integer, default: 0
    add_column :sites, :last_30_days_dev_player_hits_total_count, :integer, default: 0

    add_index :sites, :last_30_days_main_player_hits_total_count
    add_index :sites, :last_30_days_extra_player_hits_total_count
    add_index :sites, :last_30_days_dev_player_hits_total_count

    remove_column :sites, :loader_hits_cache
    remove_column :sites, :player_hits_cache
    remove_column :sites, :flash_hits_cache
    remove_column :sites, :requests_s3_cache
    remove_column :sites, :traffic_s3_cache
    remove_column :sites, :traffic_voxcast_cache

    add_index :sites, :plan_id
  end

  def self.down
    remove_index :sites, :plan_id

    add_column :sites, :loader_hits_cache, :integer
    add_column :sites, :player_hits_cache, :integer
    add_column :sites, :flash_hits_cache, :integer
    add_column :sites, :requests_s3_cache, :integer
    add_column :sites, :traffic_s3_cache, :integer
    add_column :sites, :traffic_voxcast_cache, :integer

    remove_column :sites, :extra_hostnames
    remove_column :sites, :plan_id
    remove_column :sites, :pending_plan_id
    remove_column :sites, :next_cycle_plan_id
    remove_column :sites, :cdn_up_to_date
    remove_column :sites, :first_paid_plan_started_at
    remove_column :sites, :plan_started_at
    remove_column :sites, :plan_cycle_started_at
    remove_column :sites, :plan_cycle_ended_at
    remove_column :sites, :plan_player_hits_reached_notification_sent_at
    remove_column :sites, :first_plan_upgrade_required_alert_sent_at
    remove_column :sites, :refunded_at, :datetime

    remove_index :sites, :last_30_days_dev_player_hits_total_count
    remove_index :sites, :last_30_days_extra_player_hits_total_count
    remove_index :sites, :last_30_days_main_player_hits_total_count

    remove_column :sites, :last_30_days_dev_player_hits_total_count
    remove_column :sites, :last_30_days_extra_player_hits_total_count
    remove_column :sites, :last_30_days_main_player_hits_total_count
  end
end
