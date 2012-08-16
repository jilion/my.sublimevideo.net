class AddEarlyAccessToUsers < ActiveRecord::Migration
  def change
    add_column :users, :early_access, :string, default: ''
  end
end
