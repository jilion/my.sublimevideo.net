class AddExtraHostnamesToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :extra_hostnames, :string
  end
  
  def self.down
    remove_column :sites, :extra_hostnames
  end
end