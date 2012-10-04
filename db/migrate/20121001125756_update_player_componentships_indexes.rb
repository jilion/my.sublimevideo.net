class UpdatePlayerComponentshipsIndexes < ActiveRecord::Migration
  def change
    remove_index :player_componentships, :addon_id
    add_index :player_componentships, [:addon_id, :player_component_id], unique: true
  end
end
