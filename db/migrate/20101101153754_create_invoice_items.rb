class CreateInvoiceItems < ActiveRecord::Migration
  def self.up
    create_table :invoice_items do |t|
      t.integer :site_id
      t.integer :invoice_id
      t.string :item_type
      t.integer :item_id
      t.integer :price
      t.integer :overage_amount
      t.integer :overage_price
      t.date :started_on
      t.date :ended_on
      t.datetime :canceled_at
      t.integer :refund
      t.integer :refunded_invoice_item_id

      t.timestamps
    end
  end

  def self.down
    drop_table :invoice_items
  end
end
