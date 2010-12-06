class AddTransactionFeesToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :transaction_fees, :integer
  end
  
  def self.down
    remove_column :invoices, :transaction_fees
  end
end