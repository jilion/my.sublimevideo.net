class RenamePublicAtToStableAtInAppDesignsAndAddonPlans < ActiveRecord::Migration
  def up
    rename_column :app_designs, :stable_at, :stable_at
    rename_column :addon_plans, :stable_at, :stable_at
  end

  def down
    rename_column :app_designs, :stable_at, :stable_at
    rename_column :addon_plans, :stable_at, :stable_at
  end
end
