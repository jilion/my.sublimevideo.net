class AddVipToUsers < ActiveRecord::Migration
  def change
    add_column :users, :vip, :boolean, default: false
  end
end