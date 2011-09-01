class AddTrialStartedAtToSites < ActiveRecord::Migration
  def change
    add_column :sites, :trial_started_at, :datetime
  end
end