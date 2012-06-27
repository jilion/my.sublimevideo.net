class AddRenewFieldToInvoices < ActiveRecord::Migration
  def self.up
    add_column :invoices, :renew, :boolean, default: false
  end

  def self.down
    remove_column :invoices, :renew
  end
end