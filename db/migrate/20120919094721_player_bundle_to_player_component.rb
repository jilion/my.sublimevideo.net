class PlayerBundleToPlayerComponent < ActiveRecord::Migration
  def change
    remove_index  :player_bundles, name: 'index_player_bundles_on_token'
    remove_index  :player_bundles, name: 'index_player_bundles_on_name'
    remove_column :player_bundles, :version_tags
    rename_table  :player_bundles, :player_components
    add_index :player_components, :token, unique: true
    add_index :player_components, :name, unique: true

    remove_index  :player_bundle_versions, name: 'index_player_bundle_versions_on_player_bundle_id_and_version'
    remove_column :player_bundle_versions, :settings
    rename_table  :player_bundle_versions, :player_component_versions
    rename_column :player_component_versions, :player_bundle_id, :player_component_id
    add_column :player_component_versions, :dependencies, :hstore
    add_index :player_component_versions, [:player_component_id, :version], unique: true, name:
      'index_component_versions_on_component_id_and_version'

    remove_index :player_bundleships, name: 'index_player_bundleships_on_player_bundle_id'
    remove_index :player_bundleships, name: 'index_player_bundleships_on_site_id'
    drop_table :player_bundleships
  end
end
