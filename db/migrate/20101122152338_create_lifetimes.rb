class CreateLifetimes < ActiveRecord::Migration
  def self.up
    create_table :lifetimes do |t|
      t.integer :site_id
      t.string :item_type
      t.integer :item_id
      t.datetime :created_at
      t.datetime :deleted_at
    end
    
    add_index :lifetimes, [:site_id, :item_type, :item_id, :deleted_at], :unique => true, :name => "index_lifetimes_deleted_at"
    add_index :lifetimes, [:site_id, :item_type, :item_id, :created_at], :name => "index_lifetimes_created_at"
  end
  
  def self.down
    remove_index :lifetimes, :name => "index_lifetimes_deleted_at"
    remove_index :lifetimes, :name => "index_lifetimes_created_at"
    drop_table :lifetimes
  end
end