class InvoicesTransactions < ActiveRecord::Migration
  def self.up
    create_table :invoices_transactions, :id => false do |t|
      t.integer :invoice_id
      t.integer :transaction_id
    end
  end

  def self.down
    drop_table :invoices_transactions
  end
end