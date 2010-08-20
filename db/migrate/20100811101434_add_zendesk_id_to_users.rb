class AddZendeskIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :zendesk_id, :integer
  end
  
  def self.down
    remove_column :users, :zendesk_id
  end
end