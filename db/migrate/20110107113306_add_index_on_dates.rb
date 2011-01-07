class AddIndexOnDates < ActiveRecord::Migration
  def self.up
    add_index :users, :created_at
    add_index :users, :current_sign_in_at
  end

  def self.down
    remove_index :users, :current_sign_in_at
    remove_index :users, :created_at
  end
end