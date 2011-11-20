class AddReferrerSiteTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :referrer_site_token, :string

    add_index :users, :referrer_site_token
  end
end
