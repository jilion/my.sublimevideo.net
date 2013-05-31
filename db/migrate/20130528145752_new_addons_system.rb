class NewAddonsSystem < ActiveRecord::Migration
  def up
    rename_table :app_designs, :designs

    rename_column :kits, :app_design_id, :design_id

    rename_column :app_plugins, :app_design_id, :design_id

    execute <<-EOS
    UPDATE billable_items
    SET item_type = 'Design'
    WHERE item_type = 'App::Design'
    EOS

    execute <<-EOS
    UPDATE billable_item_activities
    SET item_type = 'Design'
    WHERE item_type = 'App::Design'
    EOS

    execute <<-EOS
    UPDATE invoice_items
    SET type = 'InvoiceItem::Design', item_type = 'Design'
    WHERE type = 'InvoiceItem::AppDesign'
    EOS
  end

  def down
    rename_table :designs, :app_designs

    rename_column :kits, :design_id, :app_design_id

    rename_column :app_plugins, :design_id, :app_design_id
  end
end