class AddTrialStartedAtAndBadgedToSitesAndSupportLevelToPlans < ActiveRecord::Migration
  def change
    add_column :sites, :trial_started_at, :datetime
    add_column :sites, :badged, :boolean
    add_column :plans, :support_level, :integer, :default => 0
  end
end