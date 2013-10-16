class RemoveConditionFromAppPlugins < ActiveRecord::Migration
  def change
    remove_column :app_plugins, :condition
  end
end
