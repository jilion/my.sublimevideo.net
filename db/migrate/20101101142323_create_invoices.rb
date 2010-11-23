class CreateInvoices < ActiveRecord::Migration
  def self.up
    drop_table :invoices if Invoice.table_exists? # remove old invoices table
    
    create_table :invoices do |t|
      t.integer  :user_id
      
      t.string   :reference
      t.string   :state
      t.integer  :amount
      
      t.datetime  :started_at
      t.datetime  :ended_at
      t.datetime  :paid_at
      
      t.integer  :attempts, :default => 0
      t.string   :last_error
      t.datetime :failed_at
      
      t.timestamps
    end
    
    add_index :invoices, :user_id
    add_index :invoices, [:user_id, :started_at], :unique => true
    add_index :invoices, [:user_id, :ended_at], :unique => true
  end
  
  def self.down
    remove_index :invoices, :user_id
    remove_index :invoices, [:user_id, :started_at]
    remove_index :invoices, [:user_id, :ended_at]
    drop_table :invoices
  end
end