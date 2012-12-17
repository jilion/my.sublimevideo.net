class AddIndexOnSitesToken < ActiveRecord::Migration
  def change
    add_index :sites, :token
  end
end
