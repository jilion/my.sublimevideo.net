class CreateInvoicesAndInvoiceItems < ActiveRecord::Migration
  def self.up
    create_table :invoices do |t|
      t.integer  :site_id

      t.string   :reference
      t.string   :state

      t.integer :amount
      t.float   :vat_rate
      t.integer :vat_amount
      t.float   :discount_rate
      t.integer :discount_amount
      t.integer :invoice_items_amount
      t.integer :charging_delayed_job_id

      t.integer :invoice_items_count, :default => 0
      t.integer :transactions_count, :default => 0

      t.timestamps
      t.datetime :paid_at
      t.datetime :failed_at
    end
    add_index :invoices, :site_id
    add_index :invoices, :reference, :unique => true

    create_table :invoice_items do |t|
      t.string   :type
      t.integer  :invoice_id

      t.string   :item_type
      t.integer  :item_id

      t.datetime  :started_at
      t.datetime  :ended_at

      t.integer   :price
      t.integer   :amount

      t.text     :info # serialized

      t.timestamps
    end
    add_index :invoice_items, :invoice_id
    add_index :invoice_items, [:item_type, :item_id]
  end

  def self.down
    drop_table :invoice_items
    drop_table :invoices
  end
end
