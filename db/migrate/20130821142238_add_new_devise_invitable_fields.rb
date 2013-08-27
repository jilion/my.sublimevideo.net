class AddNewDeviseInvitableFields < ActiveRecord::Migration
  def change
    add_column :admins, :invitation_created_at, :datetime
    add_column :users, :invitation_created_at, :datetime
  end
end
