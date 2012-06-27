class RemoveEnthusiastsAndEnthusiastSites < ActiveRecord::Migration
  def self.up
    drop_table :enthusiast_sites
    drop_table :enthusiasts
  end

  def self.down
    create_table :enthusiasts do |t|
      t.references  :user
      t.string      :email
      t.text        :free_text
      t.confirmable
      t.timestamps
    end
    add_index :enthusiasts, :email, unique: true
    
    create_table :enthusiast_sites do |t|
      t.references :enthusiast
      t.string     :hostname
      t.timestamps
    end
    add_index :enthusiast_sites, :enthusiast_id
  end
end
