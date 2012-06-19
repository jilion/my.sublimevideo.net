class AddPlayerModeToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :player_mode, :string, default: "stable"
  end
  
  def self.down
    remove_column :sites, :player_mode
  end
end