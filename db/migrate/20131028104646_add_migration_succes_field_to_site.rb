class AddMigrationSuccesFieldToSite < ActiveRecord::Migration
  def change
    add_column :sites, :stats_migration_success, :boolean, default: false
  end
end
