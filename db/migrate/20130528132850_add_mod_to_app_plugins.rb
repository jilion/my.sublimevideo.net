class AddModToAppPlugins < ActiveRecord::Migration
  def change
    add_column :app_plugins, :mod, :string
  end
end