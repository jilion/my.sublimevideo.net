class CreatePlayerBundleships < ActiveRecord::Migration
  def change
    create_table :player_bundleships do |t|
      t.references :site
      t.references :player_bundle
      t.string :version_tag

      t.timestamps
    end
    add_index :player_bundleships, :site_id
    add_index :player_bundleships, :player_bundle_id
  end
end
