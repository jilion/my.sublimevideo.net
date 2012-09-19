class CreatePlayerComponentships < ActiveRecord::Migration
  def change
    create_table :player_componentships do |t|
      t.references :player_component
      t.references :addon

      t.timestamps
    end
    add_index :player_componentships, :player_component_id
    add_index :player_componentships, :addon_id

  end
end
