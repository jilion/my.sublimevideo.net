class ModifyUsers < ActiveRecord::Migration
  def self.up
    change_column :users, :cc_last_digits, :string

    add_column :users, :cc_alias, :string
    add_column :users, :pending_cc_type, :string
    add_column :users, :pending_cc_last_digits, :string
    add_column :users, :pending_cc_expire_on, :date
    add_column :users, :pending_cc_updated_at, :datetime
    
    add_column :users, :archived_at, :datetime
    add_column :users, :newsletter, :boolean, default: true
    add_column :users, :last_invoiced_amount, :integer, default: 0
    add_column :users, :total_invoiced_amount, :integer, default: 0

    remove_column :users, :trial_ended_at
    remove_column :users, :trial_usage_information_email_sent_at
    remove_column :users, :trial_usage_warning_email_sent_at
    remove_column :users, :limit_alert_amount
    remove_column :users, :limit_alert_email_sent_at
    remove_column :users, :invoices_count
    remove_column :users, :last_invoiced_on
    remove_column :users, :next_invoiced_on
    remove_column :users, :video_settings

    remove_index :users, column: [:email]
    add_index :users, [:email, :archived_at], unique: true
    add_index :users, :cc_alias, unique: true
    add_index :users, :created_at
    add_index :users, :current_sign_in_at
    add_index :users, :last_invoiced_amount
    add_index :users, :total_invoiced_amount
  end

  def self.down
    change_column :users, :cc_last_digits, :string

    add_column :users, :invoices_count, :integer, default: 0
    add_column :users, :last_invoiced_on, :date
    add_column :users, :next_invoiced_on, :date
    add_column :users, :video_settings, :text

    remove_column :users, :cc_alias
    remove_column :users, :pending_cc_type
    remove_column :users, :pending_cc_last_digits
    remove_column :users, :pending_cc_expire_on
    remove_column :users, :pending_cc_updated_at
    remove_column :users, :archived_at
    remove_column :users, :newsletter
    remove_column :users, :total_invoiced_amount
    remove_column :users, :last_invoiced_amount

    remove_index :users, column: [:email, :archived_at]
    remove_index :users, :cc_alias
    add_index :users, [:email], unique: true
    remove_index :users, :current_sign_in_at
    remove_index :users, :created_at
    remove_index :users, :total_invoiced_amount
    remove_index :users, :last_invoiced_amount
  end
end
