class AddDeletedAdToAppComponentVersions < ActiveRecord::Migration
  def change
    add_column :app_component_versions, :deleted_at, :datetime
  end
end
