class AddTrialStartedAtAndBadgedToSites < ActiveRecord::Migration
  def change
    add_column :sites, :trial_started_at, :datetime
    add_column :sites, :badged, :boolean
  end
end