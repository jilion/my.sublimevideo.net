class CreateInvoicesAndInvoiceItems < ActiveRecord::Migration
  def self.up
    drop_table :invoices

    create_table :invoices do |t|
      t.integer :site_id

      t.string  :reference
      t.string  :state

      t.string  :customer_full_name
      t.string  :customer_email
      t.string  :customer_country
      t.string  :customer_company_name

      t.string  :site_hostname

      t.integer :amount
      t.float   :vat_rate
      t.integer :vat_amount
      t.integer :invoice_items_amount

      t.integer :invoice_items_count, default: 0
      t.integer :transactions_count, default: 0

      t.timestamps
      t.datetime :paid_at
      t.datetime :last_failed_at
    end
    add_index :invoices, :site_id
    add_index :invoices, :reference, unique: true

    create_table :invoice_items do |t|
      t.string   :type       # STI
      t.integer  :invoice_id

      t.string   :item_type  # Polymorphic (e.g Plan)
      t.integer  :item_id

      t.datetime  :started_at
      t.datetime  :ended_at

      t.float     :discounted_percentage # ex. beta discount 0.2

      t.integer   :price  # always positive
      t.integer   :amount # can be negative (deduct)

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
