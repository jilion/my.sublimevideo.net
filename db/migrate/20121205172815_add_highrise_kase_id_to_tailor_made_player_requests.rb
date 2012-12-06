class AddHighriseKaseIdToTailorMadePlayerRequests < ActiveRecord::Migration
  def change
    add_column :tailor_made_player_requests, :highrise_kase_id, :integer
  end
end
