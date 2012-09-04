class UpdateEarlyAccessToText < ActiveRecord::Migration
  def up
    change_column :users, :early_access, :text
    change_column_default :users, :early_access, nil
  end

  def down
    change_column :users, :early_access, :string
    change_column_default :users, :early_access, ''
  end
end
