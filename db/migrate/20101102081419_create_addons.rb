class CreateAddons < ActiveRecord::Migration
  def self.up
    create_table :addons do |t|
      t.string  :name
      t.string  :term_type
      t.integer :price
      
      t.timestamps
    end
  end
  
  def self.down
    drop_table :addons
  end
end