class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      t.string :state
      t.string   "email",                               default: "", null: false
      t.string   "encrypted_password",   limit: 128, default: "", null: false
      t.string   "password_salt",                       default: "", null: false
      t.string :full_name
      t.string   "confirmation_token"
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.string   "reset_password_token"
      t.string   "remember_token"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",                                  default: 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.integer  "failed_attempts",                                default: 0
      t.datetime "locked_at"
      
      t.integer :invoices_count, default: 0
      t.date :last_invoiced_on,  default: nil
      t.date :next_invoiced_on,  default: nil
      
      # Trial
      t.datetime :trial_ended_at,                        default: nil
      t.datetime :trial_usage_information_email_sent_at, default: nil
      t.datetime :trial_usage_warning_email_sent_at,     default: nil
      
      # $ limit alert
      t.integer  :limit_alert_amount,        default: 0
      t.datetime :limit_alert_email_sent_at, default: nil
      
      # Credit Card
      t.string   :cc_type
      t.integer  :cc_last_digits
      t.date     :cc_expire_on
      t.datetime :cc_updated_at
      
      # Video settings
      t.text     :video_settings
      
      t.timestamps
    end
    
    add_index :users, :email,                unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :reset_password_token, unique: true
  end
  
  def self.down
    drop_table :users
  end
end
