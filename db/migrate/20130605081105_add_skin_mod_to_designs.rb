class AddSkinModToDesigns < ActiveRecord::Migration
  def up
    add_column :designs, :skin_mod, :string
  end

  def down
    remove_column :designs, :skin_mod
  end
end
