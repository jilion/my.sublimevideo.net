class AddAddonsSettingsToSites < ActiveRecord::Migration
  def change
    add_column :sites, :addons_settings, :hstore
  end
end
