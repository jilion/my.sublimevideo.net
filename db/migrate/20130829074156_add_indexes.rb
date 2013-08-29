class AddIndexes < ActiveRecord::Migration
  def change
    add_index :sites, [:id, :state]
    add_index :users, [:id, :state]
    add_index :billable_item_activities, [:site_id, :item_type, :item_id, :state, :created_at], name: 'billable_item_activities_big_index'
  end
end
