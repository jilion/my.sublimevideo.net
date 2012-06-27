class AddInvitationFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :invitation_token, :string, limit: 20
    add_column :users, :invitation_sent_at, :datetime
  end
  
  def self.down
    remove_column :users, :invitation_sent_at
    remove_column :users, :invitation_token
  end
end