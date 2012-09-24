class CreateAddonActivities < ActiveRecord::Migration
  def change
    create_table :addon_activities do |t|
      t.references :addonship, null: false
      t.string     :state, null: false

      t.timestamps
    end
    add_index :addon_activities, :addonship_id
  end
end
