class AddVatRateAndVatAmountToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :vat_rate, :float
    add_column :invoices, :vat_amount, :integer
  end
  
  def self.down
    remove_column :invoices, :vat_amount
    remove_column :invoices, :vat_rate
  end
end