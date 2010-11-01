class CreateInvoiceItems < ActiveRecord::Migration
  def self.up
    create_table :invoice_items do |t|
      t.integer  :site_id
      t.integer  :invoice_id
      
      t.string   :item_type
      t.integer  :item_id
      
      t.date     :started_on
      t.date     :ended_on
      t.datetime :canceled_at
      
      t.integer  :price
      t.integer  :overage_amount, :default => 0
      t.integer  :overage_price
      t.integer  :refund, :default => 0
      t.integer  :refunded_invoice_item_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :invoice_items
  end
end
