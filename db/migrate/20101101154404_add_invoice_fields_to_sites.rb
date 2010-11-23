class AddInvoiceFieldsToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :plan_id, :integer
    add_index :sites, :plan_id
  end
  
  def self.down
    remove_index :sites, :plan_id
    remove_column :sites, :plan_id
  end
end