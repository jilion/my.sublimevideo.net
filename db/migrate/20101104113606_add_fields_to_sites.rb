class AddFieldsToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :cdn_up_to_date, :boolean
    add_column :sites, :paid_plan_cycle_started_at, :datetime
    add_column :sites, :paid_plan_cycle_ended_at, :datetime
    add_column :sites, :next_cycle_plan_id, :integer
  end

  def self.down
    remove_column :sites, :cdn_up_to_date
    remove_column :sites, :paid_plan_cycle_started_at
    remove_column :sites, :paid_plan_cycle_ended_at
    remove_column :sites, :next_cycle_plan_id
  end
end