class AddIdentifierFieldInKits < ActiveRecord::Migration
  def up
    add_column :kits, :identifier, :string
  end

  def down
    remove_column :kits, :identifier, :string
  end
end
