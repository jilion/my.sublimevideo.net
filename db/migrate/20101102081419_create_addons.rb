class CreateAddons < ActiveRecord::Migration
  def self.up
    create_table :addons do |t|
      t.string  :name
      t.integer :price
      
      t.timestamps
    end
    
    add_index :addons, :name, :unique => true
  end
  
  def self.down
    remove_index :addons, :name
    drop_table :addons
  end
end