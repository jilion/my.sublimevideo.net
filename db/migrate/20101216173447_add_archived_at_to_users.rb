class AddArchivedAtToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :archived_at, :datetime
  end
  
  def self.down
    remove_column :users, :archived_at
  end
end