class ChangeDefaultOfKitNameAndAddDefaultPlayerIdToSites < ActiveRecord::Migration
  def up
    add_column :sites, :default_kit_id, :integer
    change_column_default :kits, :name, nil
  end

  def down
    remove_column :sites, :default_kit_id
    change_column_default :kits, :name, 'Default'
  end
end
