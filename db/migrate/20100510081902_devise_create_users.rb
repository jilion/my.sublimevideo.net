class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      t.string :state
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
      
      t.datetime :trial_ended_at, :default => nil
      t.datetime :trial_usage_information_email_sent_at, :default => nil
      t.datetime :trial_usage_warning_email_sent_at, :default => nil
      
      t.string :cc_type
      t.integer :cc_last_digits
      t.datetime :cc_updated_at
      
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
