class AddIndexToAppComponentVersions < ActiveRecord::Migration
  def change
    add_index :app_component_versions, [:deleted_at, :app_component_id]
  end
end
