class CreateMailLogs < ActiveRecord::Migration
  def self.up
    create_table :mail_logs do |t|
      t.integer :template_id
      t.integer :admin_id
      t.text :criteria # criteria used to select user_ids (serialized form params)
      t.text :user_ids # IDs of users who've been sent the mail
      t.text :snapshot # snapshot of the template, serialization of Mail::Template
      t.timestamps
    end
    
    add_index :mail_logs, :template_id
    
  end
  
  def self.down
    drop_table :mail_logs
  end
end
