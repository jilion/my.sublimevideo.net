class CreateMail::Templates < ActiveRecord::Migration
  def self.up
    create_table :mail_templates do |t|
      t.string :title
      t.string :subject
      t.text :body
      t.timestamps
    end
  end
  
  def self.down
    drop_table :mail_templates
  end
end
