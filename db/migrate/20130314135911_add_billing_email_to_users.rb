class AddBillingEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :billing_email, :string
  end
end