class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.string :hostname
      t.string :dev_hostnames
      t.string :token
      t.string :state

      t.timestamps
    end
  end

  def self.down
    drop_table :sites
  end
end
