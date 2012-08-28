class CreatePlayerBundles < ActiveRecord::Migration
  def change
    create_table :player_bundles do |t|
      t.string :token
      t.string :name
      t.hstore :version_tags

      t.timestamps
    end

    add_index :player_bundles, :token, unique: true
    add_index :player_bundles, :name, unique: true
  end
end
