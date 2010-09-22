class AddDomainSpecificFieldsToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :alias_hostnames, :string
    add_column :sites, :path, :string
    add_column :sites, :wildcard, :boolean
  end
  
  def self.down
    remove_column :sites, :alias_hostnames
    remove_column :sites, :path
    remove_column :sites, :wildcard
  end
end
