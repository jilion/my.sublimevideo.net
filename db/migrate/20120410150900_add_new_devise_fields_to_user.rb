class AddNewDeviseFieldsToUser < ActiveRecord::Migration
  def change
    change_column :users, :invitation_token, :string, limit: 60
    add_column :users, :invitation_accepted_at, :datetime
    add_column :users, :invitation_limit, :integer
    add_column :users, :invited_by_id, :integer
    add_column :users, :invited_by_type, :string
  end
end
