class AddInvoiceItemsCountToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :invoice_items_count, :integer
  end

  def self.down
    remove_column :invoices, :invoice_items_count
  end
end