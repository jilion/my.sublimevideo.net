class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.references :user
      
      t.string  :hostname
      t.string  :dev_hostnames
      t.string  :token
      t.string  :license
      t.string  :loader
      t.string  :state
      
      t.integer :loader_hits_cache,  default: 0
      t.integer :player_hits_cache,  default: 0
      t.integer :flash_hits_cache,   default: 0
      
      t.datetime :archived_at
      
      t.timestamps
    end
    
    add_index :sites, :user_id
    add_index :sites, :hostname
    add_index :sites, :created_at
    add_index :sites, [:player_hits_cache, :user_id]
  end
  
  def self.down
    drop_table :sites
  end
end
