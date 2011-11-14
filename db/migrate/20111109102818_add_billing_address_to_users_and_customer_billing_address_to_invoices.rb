class AddBillingAddressToUsersAndCustomerBillingAddressToInvoices < ActiveRecord::Migration
  def change
    add_column :users, :street_1, :string
    add_column :users, :street_2, :string
    add_column :users, :city, :string
    add_column :users, :region, :string
    add_column :invoices, :customer_billing_address, :text
  end
end