class CreateInvoiceItems < ActiveRecord::Migration
  def self.up
    create_table :invoice_items do |t|
      t.string   :type
      t.integer  :site_id
      t.integer  :invoice_id
      
      t.string   :item_type
      t.integer  :item_id
      
      t.date     :started_on
      t.date     :ended_on
      t.datetime :canceled_at
      
      t.integer  :price
      t.integer  :amount
      
      t.text     :info # serialized
      
      t.timestamps
    end
    
    add_index :invoice_items, :site_id
    add_index :invoice_items, :invoice_id
    add_index :invoice_items, [:item_type, :item_id]
  end
  
  def self.down
    remove_index :invoice_items, [:item_type, :item_id]
    remove_index :invoice_items, :invoice_id
    remove_index :invoice_items, :site_id
    drop_table :invoice_items
  end
end