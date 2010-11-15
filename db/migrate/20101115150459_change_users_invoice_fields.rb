class ChangeUsersInvoiceFields < ActiveRecord::Migration
  def self.up
    remove_column :users, :invoices_count
    remove_column :users, :last_invoiced_on
    remove_column :users, :billable_on
    add_column :users, :billable_on, :date
    
    add_index :users, :billable_on
  end
  
  def self.down
    remove_index :users, :billable_on
    
    remove_column :users, :billable_on
    add_column :users, :billable_on, :date
    add_column :users, :last_invoiced_on, :date
    add_column :users, :invoices_count, :integer, :default => 0
  end
end