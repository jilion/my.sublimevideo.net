class RemovedUnusedIndexes < ActiveRecord::Migration
  def change
    remove_index :versions, [:item_type, :item_id]
    remove_index :billable_item_activities, [:item_type, :item_id]
    remove_index :users, :current_sign_in_at
    remove_index :users, :last_invoiced_amount
    remove_index :users, :referrer_site_token
    remove_index :users, :total_invoiced_amount
    remove_index :sites, :hostname
    remove_index :sites, :first_admin_starts_on
  end
end
