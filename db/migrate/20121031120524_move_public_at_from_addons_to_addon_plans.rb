class MovePublicAtFromAddonsToAddonPlans < ActiveRecord::Migration
  def up
    remove_column :addons, :public_at
    add_column :addon_plans, :public_at, :datetime
  end

  def down
    remove_column :addon_plans, :public_at
    add_column :addons, :public_at, :datetime
  end
end
