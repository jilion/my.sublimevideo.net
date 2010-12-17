class ChangeUniqueEmailIndexInUsers < ActiveRecord::Migration
  def self.up
    remove_index :users, :column => [:email]
    add_index :users, [:email, :archived_at], :unique => true
  end
  
  def self.down
    remove_index :users, :column => [:email, :archived_at]
    add_index :users, [:email], :unique => true
  end
end