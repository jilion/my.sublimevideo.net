class AddFieldsToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :cdn_up_to_date, :boolean
    add_column :sites, :activated_at, :datetime
  end
  
  def self.down
    remove_column :sites, :activated_at
    remove_column :sites, :cdn_up_to_date
  end
end