class DeviseCreateAdmins < ActiveRecord::Migration
  def self.up
    create_table :admins do |t|
      t.string   "email",                               default: "", null: false
      t.string   "encrypted_password",   limit: 128, default: "", null: false
      t.string   "password_salt",                       default: "", null: false
      t.string   "reset_password_token"
      t.string   "remember_token"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",                       default: 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.integer  "failed_attempts",                     default: 0
      t.datetime "locked_at"
      t.string   "invitation_token",     limit: 20
      t.datetime "invitation_sent_at"
      t.timestamps
    end
    
    add_index :admins, :email,                unique: true
    add_index :admins, :reset_password_token, unique: true
    add_index :admins, :invitation_token # for invitable
  end
  
  def self.down
    drop_table :admins
  end
end