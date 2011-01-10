class AddLast30DaysCountersToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :last_30_days_main_player_hits_total_count, :integer, :default => 0
    add_column :sites, :last_30_days_extra_player_hits_total_count, :integer, :default => 0
    add_column :sites, :last_30_days_dev_player_hits_total_count, :integer, :default => 0

    add_index :sites, :last_30_days_main_player_hits_total_count
    add_index :sites, :last_30_days_extra_player_hits_total_count
    add_index :sites, :last_30_days_dev_player_hits_total_count
  end

  def self.down
    remove_index :sites, :last_30_days_dev_player_hits_total_count
    remove_index :sites, :last_30_days_extra_player_hits_total_count
    remove_index :sites, :last_30_days_main_player_hits_total_count

    remove_column :sites, :last_30_days_dev_player_hits_total_count
    remove_column :sites, :last_30_days_extra_player_hits_total_count
    remove_column :sites, :last_30_days_main_player_hits_total_count
  end
end