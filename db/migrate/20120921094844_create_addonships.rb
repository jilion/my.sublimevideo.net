class CreateAddonships < ActiveRecord::Migration
  def change
    create_table :addonships do |t|
      t.references :site, null: false
      t.references :addon, null: false
      t.string     :state, null: false
      t.datetime   :trial_started_on

      t.timestamps
    end
    add_index :addonships, [:site_id, :addon_id], unique: true
    add_index :addonships, :addon_id
    add_index :addonships, :state
    add_index :addonships, :trial_started_on
  end
end
