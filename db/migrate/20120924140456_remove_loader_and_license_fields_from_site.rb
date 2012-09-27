class RemoveLoaderAndLicenseFieldsFromSite < ActiveRecord::Migration
  def change
    remove_column :sites, :loader
    remove_column :sites, :license
  end
end
