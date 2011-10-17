class AddStatsTrialStartedAtToSites < ActiveRecord::Migration
  def change
    add_column :sites, :stats_trial_started_at, :datetime
  end
end
