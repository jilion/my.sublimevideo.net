class CreateEnthusiastSites < ActiveRecord::Migration
  def self.up
    create_table :enthusiast_sites do |t|
      t.references :enthusiast
      t.string     :hostname
      t.timestamps
    end
    
    add_index :enthusiast_sites, :enthusiast_id
  end
  
  def self.down
    drop_table :enthusiast_sites
  end
end
