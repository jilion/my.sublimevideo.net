class AddNewDeviseFields < ActiveRecord::Migration
  def change
    add_column :admins, :reset_password_sent_at, :datetime
    add_column :admins, :remember_token, :string
    change_column :admins, :invitation_token, :string, limit: 60
    add_column :admins, :invitation_accepted_at, :datetime
    add_column :admins, :invitation_limit, :integer
    add_column :admins, :invited_by_id, :integer
    add_column :admins, :invited_by_type, :string

    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :remember_token, :string
  end
end
