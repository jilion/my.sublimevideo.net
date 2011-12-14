class RemoveStatsTrialStartedAtFromSites < ActiveRecord::Migration
  def change
    remove_column :sites, :stats_trial_started_at
  end
end
