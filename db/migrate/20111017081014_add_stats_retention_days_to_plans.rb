class AddStatsRetentionDaysToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :stats_retention_days, :integer
  end
end
