class CreateInvoices < ActiveRecord::Migration
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
  end

  def self.down
    remove_index :invoices, :site_id
    drop_table :invoices
  end
end