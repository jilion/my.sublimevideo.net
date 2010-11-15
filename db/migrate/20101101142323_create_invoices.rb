class CreateInvoices < ActiveRecord::Migration
  def self.up
    drop_table :invoices if Invoice.table_exists? # remove old invoices table
    
    create_table :invoices do |t|
      t.integer  :user_id
      
      t.string   :reference
      t.string   :state
      t.integer  :amount
      
      t.date     :billed_on
      t.datetime :paid_at
      
      t.integer  :attempts, :default => 0
      t.string   :last_error
      t.datetime :failed_at
      
      t.timestamps
    end
    
    add_index :invoices, :user_id
  end
  
  def self.down
    drop_table :invoices
    
    remove_index :invoices, :user_id
  end
end