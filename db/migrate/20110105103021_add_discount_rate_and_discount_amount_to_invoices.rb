class AddDiscountRateAndDiscountAmountToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :discount_rate, :float, :default => 0.0
    add_column :invoices, :discount_amount, :float, :default => 0.0
  end

  def self.down
    remove_column :invoices, :discount_amount
    remove_column :invoices, :discount_rate
  end
end