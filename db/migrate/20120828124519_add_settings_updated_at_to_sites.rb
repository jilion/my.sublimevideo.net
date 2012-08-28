class AddSettingsUpdatedAtToSites < ActiveRecord::Migration
  def change
    add_column :sites, :settings_updated_at, :datetime
  end
end
