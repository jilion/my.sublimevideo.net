class CreatePlayerBundleVersions < ActiveRecord::Migration
  def change
    create_table :player_bundle_versions do |t|
      t.references :player_bundle
      t.string :version
      t.text :settings
      t.string :zip

      t.timestamps
    end
    add_index :player_bundle_versions, [:player_bundle_id, :version], unique: true
  end
end
