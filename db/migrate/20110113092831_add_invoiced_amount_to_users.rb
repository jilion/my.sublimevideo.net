class AddInvoicedAmountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :last_invoiced_amount, :integer, :default => 0
    add_column :users, :total_invoiced_amount, :integer, :default => 0

    add_index :users, :last_invoiced_amount
    add_index :users, :total_invoiced_amount
  end

  def self.down
    remove_index :users, :total_invoiced_amount
    remove_index :users, :last_invoiced_amount

    remove_column :users, :total_invoiced_amount
    remove_column :users, :last_invoiced_amount
  end
end