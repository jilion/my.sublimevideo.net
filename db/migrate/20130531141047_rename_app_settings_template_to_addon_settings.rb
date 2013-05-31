class RenameAppSettingsTemplateToAddonSettings < ActiveRecord::Migration
  def up
    rename_table :app_settings_templates, :addon_plan_settings
  end

  def down
    rename_table :addon_plan_settings, :app_settings_templates
  end
end
