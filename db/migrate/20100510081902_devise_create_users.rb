class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      t.database_authenticatable :null => false
      t.string :full_name
      t.confirmable
      t.recoverable
      t.rememberable
      t.trackable
      
      t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :time
      # t.token_authenticatable
      
      t.datetime :last_invoiced_at,  :default => nil
      t.datetime :next_invoiced_at,  :default => nil
      
      t.timestamps
    end
    
    add_index :users, :email,                :unique => true
    add_index :users, :confirmation_token,   :unique => true
    add_index :users, :reset_password_token, :unique => true
    # add_index :users, :unlock_token,         :unique => true
  end
  
  def self.down
    drop_table :users
  end
end
