class AddUnconfirmedEmailToAdminsAndUsers < ActiveRecord::Migration
  def change
    add_column :admins, :unconfirmed_email, :string
    add_column :users, :unconfirmed_email, :string
  end
end
