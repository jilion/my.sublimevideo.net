class AddArchivedAtToMailTemplate < ActiveRecord::Migration
  def change
    add_column :mail_templates, :archived_at, :datetime
  end
end