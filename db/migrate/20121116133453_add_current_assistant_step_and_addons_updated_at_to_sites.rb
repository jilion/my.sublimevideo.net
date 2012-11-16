class AddCurrentAssistantStepAndAddonsUpdatedAtToSites < ActiveRecord::Migration
  def change
    add_column :sites, :current_assistant_step, :string
    add_column :sites, :addons_updated_at, :datetime
  end
end
