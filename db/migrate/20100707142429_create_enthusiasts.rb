class CreateEnthusiasts < ActiveRecord::Migration
  def self.up
    create_table :enthusiasts do |t|
      t.references  :user
      t.string      :email
      t.text        :free_text
      t.confirmable
      t.timestamps
    end
    
    add_index :enthusiasts, :email, unique: true
  end
  
  def self.down
    drop_table :enthusiasts
  end
end
