class AddInvoiceFieldsToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :plan_id, :integer
  end
  
  def self.down
    remove_column :sites, :plan_id
  end
end