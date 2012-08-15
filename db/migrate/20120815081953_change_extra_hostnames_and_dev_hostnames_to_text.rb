class ChangeExtraHostnamesAndDevHostnamesToText < ActiveRecord::Migration

  def up
    change_column :sites, :dev_hostnames, :text
    change_column :sites, :extra_hostnames, :text
  end

  def down
    # This might cause trouble if you have strings longer
    # than 255 characters.
    change_column :sites, :dev_hostnames, :string
    change_column :sites, :extra_hostnames, :string
  end

end
