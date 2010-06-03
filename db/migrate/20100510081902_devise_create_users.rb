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
      
      t.integer :invoices_count, :default => 0
      t.date :last_invoiced_on,  :default => nil
      t.date :next_invoiced_on,  :default => nil
      
      t.datetime :trial_finished_at, :default => nil
      
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
