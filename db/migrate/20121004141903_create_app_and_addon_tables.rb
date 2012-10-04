class CreateAppAndAddonTables < ActiveRecord::Migration
  def change
    create_table :site_kits do |t|
      t.references :site, null: false
      t.references :app_design, null: false
      t.string     :name, null: false, default: 'Default'
      t.hstore     :settings

      t.timestamps
    end
    add_index :site_kits, :site_id
    add_index :site_kits, :app_design_id
    add_index :site_kits, [:site_id, :name], unique: true

    create_table :app_designs do |t|
      t.references :app_component, null: false
      t.string     :skin_token, null: false
      t.string     :name, null: false
      t.integer    :price, null: false
      t.string     :availability, null: false

      t.timestamps
    end
    add_index :app_designs, :skin_token, unique: true
    add_index :app_designs, :name, unique: true

    create_table :site_addons do |t|
      t.string  :name, null: false
      t.boolean :design_dependent, null: false

      t.timestamps
    end
    add_index :site_addons, :name, unique: true

    create_table :site_addon_plans do |t|
      t.references :site_addon, null: false
      t.string     :name, null: false
      t.integer    :price, null: false
      t.string     :availability, null: false

      t.timestamps
    end
    add_index :site_addon_plans, :site_addon_id
    add_index :site_addon_plans, [:site_addon_id, :name], unique: true

    create_table :site_billable_items do |t|
      t.string     :item_type, null: false
      t.integer    :item_id, null: false
      t.references :site, null: false
      t.string     :state, null: false

      t.timestamps
    end
    add_index :site_billable_items, :site_id
    add_index :site_billable_items, [:item_type, :item_id]

    create_table :app_plugins do |t|
      t.references :site_addon, null: false
      t.references :app_design
      t.references :app_component, null: false
      t.string     :token, null: false

      t.timestamps
    end
    add_index :app_plugins, :app_design_id
    add_index :app_plugins, [:app_design_id, :site_addon_id]

    create_table :app_settings do |t|
      t.references :site_addon_plan, null: false
      t.references :app_plugin
      t.hstore     :settings_template

      t.timestamps
    end
    add_index :app_settings, [:site_addon_plan_id, :app_plugin_id]

    create_table :billing_activities do |t|
      t.string     :item_type, null: false
      t.integer    :item_id, null: false
      t.references :site, null: false
      t.string     :state, null: false

      t.timestamps
    end
    add_index :billing_activities, :site_id
    add_index :billing_activities, [:item_type, :item_id]

    rename_table :player_components, :app_components
    rename_table :player_component_versions, :app_component_versions
    drop_table   :player_componentships, :app_componentships

    rename_column :app_component_versions, :player_component_id, :app_component_id
  end
end
