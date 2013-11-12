class RemoveMigrationSuccesFieldToSite < ActiveRecord::Migration
  def change
    remove_column :sites, :stats_migration_success
  end
end
