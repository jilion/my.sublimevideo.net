class ReplaceCdnUpToDateSiteFieldByLoaderUpdatedAt < ActiveRecord::Migration
  def change
    remove_column :sites, :cdn_up_to_date
    add_column :sites, :loaders_updated_at, :datetime
  end
end
