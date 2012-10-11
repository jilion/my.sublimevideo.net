class CreateAppAndAddonTables < ActiveRecord::Migration
  def change
    create_table :kits do |t|
      t.references :site, null: false
      t.references :app_design, null: false
      t.string     :name, null: false, default: 'Default'
      t.hstore     :settings

      t.timestamps
    end
    add_index :kits, :site_id
    add_index :kits, :app_design_id
    add_index :kits, [:site_id, :name], unique: true

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

    create_table :addons do |t|
      t.string   :name, null: false
      t.boolean  :design_dependent, null: false, default: true
      t.datetime :public_at
      t.integer  :parent_addon_id
      t.string   :kind

      t.timestamps
    end
    add_index :addons, :name, unique: true

    create_table :addon_plans do |t|
      t.references :addon, null: false
      t.string     :name, null: false
      t.integer    :price, null: false
      t.string     :availability, null: false
      t.string     :required_stage, null: false, default: 'stable'

      t.timestamps
    end
    add_index :addon_plans, :addon_id
    add_index :addon_plans, [:addon_id, :name], unique: true

    create_table :billable_items do |t|
      t.references :site, null: false
      t.string     :item_type, null: false
      t.integer    :item_id, null: false
      t.string     :state, null: false

      t.timestamps
    end
    add_index :billable_items, :site_id
    add_index :billable_items, [:item_type, :item_id]
    add_index :billable_items, [:item_type, :item_id, :site_id], unique: true

    create_table :app_plugins do |t|
      t.references :addon, null: false
      t.references :app_design
      t.references :app_component, null: false
      t.string     :token, null: false
      t.string     :name, null: false

      t.timestamps
    end
    add_index :app_plugins, :app_design_id
    add_index :app_plugins, [:app_design_id, :addon_id]

    create_table :app_settings_templates do |t|
      t.references :addon_plan, null: false
      t.references :app_plugin
      t.hstore     :template

      t.timestamps
    end
    add_index :app_settings_templates, [:addon_plan_id, :app_plugin_id], unique: true

    create_table :billable_item_activities do |t|
      t.references :site, null: false
      t.string     :item_type, null: false
      t.integer    :item_id, null: false
      t.string     :state, null: false

      t.timestamps
    end
    add_index :billable_item_activities, :site_id
    add_index :billable_item_activities, [:item_type, :item_id]

    rename_table :player_components, :app_components

    rename_table :player_component_versions, :app_component_versions

    drop_table   :player_componentships

    rename_column :app_component_versions, :player_component_id, :app_component_id
  end
end
