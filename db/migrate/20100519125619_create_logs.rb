class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      t.string :name
      t.string :hostname
      t.string :state
      t.string :file
      t.datetime :started_at
      t.datetime :ended_at
      
      t.timestamps
    end
    
    add_index :logs, :name
    add_index :logs, :started_at
    add_index :logs, :ended_at
  end
  
  def self.down
    drop_table :logs
  end
end
