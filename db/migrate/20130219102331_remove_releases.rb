class RemoveReleases < ActiveRecord::Migration
  def up
    remove_index :releases, :state
    drop_table :releases
  end
end
