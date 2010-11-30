class AddInvoiceItemsAmountToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :invoice_items_amount, :integer
  end
  
  def self.down
    remove_column :invoices, :invoice_items_amount
  end
end