class CreateAddonsSites < ActiveRecord::Migration
  def self.up
    create_table :addons_sites, :id => false, :force => true do |t|
      t.integer :site_id
      t.integer :addon_id
    end

    add_index :addons_sites, :site_id
    add_index :addons_sites, :addon_id
  end

  def self.down
    remove_index :addons_sites, :addon_id
    remove_index :addons_sites, :site_id
    drop_table :addons_sites
  end
end