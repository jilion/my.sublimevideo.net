class RemoveEditableFromAppSettingsTemplates < ActiveRecord::Migration
  def change
    remove_column :app_settings_templates, :editable
  end
end
