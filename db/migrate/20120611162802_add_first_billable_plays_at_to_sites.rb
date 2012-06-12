class AddFirstBillablePlaysAtToSites < ActiveRecord::Migration
  def change
    add_column :sites, :first_billable_plays_at, :datetime
  end
end