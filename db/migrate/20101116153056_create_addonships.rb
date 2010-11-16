class CreateAddonships < ActiveRecord::Migration
  def self.up
    create_table :addonships, :force => true do |t|
      t.integer :plan_id
      t.integer :addon_id
      t.integer :price
      
      t.timestamps
    end
    
    add_index :addonships, [:plan_id, :addon_id]
    add_index :addonships, :plan_id
    add_index :addonships, :addon_id
  end
  
  def self.down
    remove_index :addonships, [:plan_id, :addon_id]
    remove_index :addonships, :addon_id
    remove_index :addonships, :plan_id
    drop_table :addonships
  end
end
