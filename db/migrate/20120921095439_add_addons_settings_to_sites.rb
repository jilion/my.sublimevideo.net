class AddAddonsSettingsToSites < ActiveRecord::Migration
  def change
    add_column :sites, :settings, :hstore
  end
end
