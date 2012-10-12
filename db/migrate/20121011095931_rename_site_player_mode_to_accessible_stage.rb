class RenameSitePlayerModeToAccessibleStage < ActiveRecord::Migration
  def change
    rename_column :sites, :player_mode, :accessible_stage
    change_column_default :sites, :accessible_stage, 'beta'
  end
end
