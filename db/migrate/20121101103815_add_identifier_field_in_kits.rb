class AddIdentifierFieldInKits < ActiveRecord::Migration
  def up
    add_column :kits, :identifier, :string
    add_index :kits, [:site_id, :identifier], unique: true
  end

  def down
    remove_column :kits, :identifier, :string
    remove_index :kits, [:site_id, :identifier]
  end
end
