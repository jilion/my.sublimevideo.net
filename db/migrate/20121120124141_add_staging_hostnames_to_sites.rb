class AddStagingHostnamesToSites < ActiveRecord::Migration
  def change
    add_column :sites, :staging_hostnames, :text
  end
end
