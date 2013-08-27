class RenameSomeIndexes < ActiveRecord::Migration
  def up
    # rename_index :designs, 'index_app_designs_on_name', 'index_designs_on_name'
    # rename_index :designs, 'index_app_designs_on_skin_token', 'index_designs_on_skin_token'

    # rename_index :app_plugins, 'index_app_plugins_on_app_design_id', 'index_app_plugins_on_design_id'
    # rename_index :app_plugins, 'index_app_plugins_on_app_design_id_and_addon_id', 'index_app_plugins_on_design_id_and_addon_id'

    # rename_index :kits, 'index_kits_on_app_design_id', 'index_kits_on_design_id'
  end

  def down
    rename_index :designs, 'index_designs_on_name', 'index_app_designs_on_name'
    rename_index :designs, 'index_designs_on_skin_token', 'index_app_designs_on_skin_token'

    rename_index :app_plugins, 'index_app_plugins_on_design_id', 'index_app_plugins_on_app_design_id'
    rename_index :app_plugins, 'index_app_plugins_on_design_id_and_addon_id', 'index_app_plugins_on_app_design_id_and_addon_id'

    rename_index :kits, 'index_kits_on_design_id', 'index_kits_on_app_design_id'
  end
end
