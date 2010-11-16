class AddInvoiceFieldsToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :plan_id, :integer
    add_column :sites, :billable_on, :date
    
    add_index :sites, :plan_id
  end
  
  def self.down
    remove_index :sites, :plan_id
    remove_column :sites, :plan_id
    remove_column :sites, :billable_on
  end
end