class AddFieldToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :newsletter, :boolean
  end

  def self.down
    remove_column :users, :newsletter
  end
end
