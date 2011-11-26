class AddBillingAddressToUsersAndCustomerBillingAddressToInvoices < ActiveRecord::Migration
  def change
    add_column :users, :name, :string
    add_column :users, :billing_name, :string
    add_column :users, :billing_address_1, :string
    add_column :users, :billing_address_2, :string
    add_column :users, :billing_postal_code, :string
    add_column :users, :billing_city, :string
    add_column :users, :billing_region, :string
    add_column :users, :billing_country, :string
    add_column :invoices, :customer_billing_address, :text
  end
end