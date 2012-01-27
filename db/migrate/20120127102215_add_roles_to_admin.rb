class AddRolesToAdmin < ActiveRecord::Migration
  def change
    add_column :admins, :roles, :text # serialized
  end
end
