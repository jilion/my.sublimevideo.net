class RemovePlansFieldsFromSites < ActiveRecord::Migration
  def change
    remove_column :sites, :first_paid_plan_started_at
    remove_column :sites, :first_plan_upgrade_required_alert_sent_at
    remove_column :sites, :next_cycle_plan_id
    remove_column :sites, :overusage_notification_sent_at
    remove_column :sites, :pending_plan_cycle_ended_at
    remove_column :sites, :pending_plan_cycle_started_at
    remove_column :sites, :pending_plan_id
    remove_column :sites, :pending_plan_started_at
    remove_column :sites, :plan_cycle_ended_at
    remove_column :sites, :plan_cycle_started_at
    remove_column :sites, :plan_started_at
  end
end
