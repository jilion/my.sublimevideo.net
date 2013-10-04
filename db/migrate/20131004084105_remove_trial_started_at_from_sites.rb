class RemoveTrialStartedAtFromSites < ActiveRecord::Migration
  def change
    remove_column :sites, :trial_started_at
  end
end
