class CreateVersions < ActiveRecord::Migration
  def self.up
    create_table :versions do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at

      # custom info fields
      t.string   :admin_id
      t.string   :ip
      t.string   :user_agent
    end
    add_index :versions, [:item_type, :item_id]
  end

  def self.down
    drop_table :versions
  end
end
