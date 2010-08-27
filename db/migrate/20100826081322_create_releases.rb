class CreateReleases < ActiveRecord::Migration
  def self.up
    create_table :releases do |t|
      t.string :token, :date
      t.string :zip
      t.string :state
      
      t.timestamps
    end
    
    add_index :releases, :state
  end
  
  def self.down
    remove_index :releases, :state
    
    drop_table :releases
  end
end
