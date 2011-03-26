# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110223160948) do

  create_table "admins", :force => true do |t|
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "", :null => false
    t.string   "password_salt",                       :default => "", :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                     :default => 0
    t.datetime "locked_at"
    t.string   "invitation_token",     :limit => 20
    t.datetime "invitation_sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "admins", ["email"], :name => "index_admins_on_email", :unique => true
  add_index "admins", ["invitation_token"], :name => "index_admins_on_invitation_token"
  add_index "admins", ["reset_password_token"], :name => "index_admins_on_reset_password_token", :unique => true

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "invoice_items", :force => true do |t|
    t.string   "type"
    t.integer  "invoice_id"
    t.string   "item_type"
    t.integer  "item_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "price"
    t.integer  "amount"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoice_items", ["invoice_id"], :name => "index_invoice_items_on_invoice_id"
  add_index "invoice_items", ["item_type", "item_id"], :name => "index_invoice_items_on_item_type_and_item_id"

  create_table "invoices", :force => true do |t|
    t.integer  "site_id"
    t.string   "reference"
    t.string   "state"
    t.string   "customer_full_name"
    t.string   "customer_email"
    t.string   "customer_country"
    t.string   "customer_company_name"
    t.integer  "amount"
    t.float    "vat_rate"
    t.integer  "vat_amount"
    t.float    "discount_rate"
    t.integer  "discount_amount"
    t.integer  "invoice_items_amount"
    t.integer  "invoice_items_count",   :default => 0
    t.integer  "transactions_count",    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "paid_at"
    t.datetime "last_failed_at"
  end

  add_index "invoices", ["reference"], :name => "index_invoices_on_reference", :unique => true
  add_index "invoices", ["site_id"], :name => "index_invoices_on_site_id"

  create_table "invoices_transactions", :id => false, :force => true do |t|
    t.integer "invoice_id"
    t.integer "transaction_id"
  end

  create_table "mail_logs", :force => true do |t|
    t.integer  "template_id"
    t.integer  "admin_id"
    t.text     "criteria"
    t.text     "user_ids"
    t.text     "snapshot"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mail_logs", ["template_id"], :name => "index_mail_logs_on_template_id"

  create_table "mail_templates", :force => true do |t|
    t.string   "title"
    t.string   "subject"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "plans", :force => true do |t|
    t.string   "name"
    t.string   "token"
    t.string   "cycle"
    t.integer  "player_hits"
    t.integer  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "plans", ["name", "cycle"], :name => "index_plans_on_name_and_cycle", :unique => true
  add_index "plans", ["token"], :name => "index_plans_on_token", :unique => true

  create_table "releases", :force => true do |t|
    t.string   "token"
    t.string   "date"
    t.string   "zip"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "releases", ["state"], :name => "index_releases_on_state"

  create_table "sites", :force => true do |t|
    t.integer  "user_id"
    t.string   "hostname"
    t.string   "dev_hostnames"
    t.string   "token"
    t.string   "license"
    t.string   "loader"
    t.string   "state"
    t.datetime "archived_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "player_mode",                                   :default => "stable"
    t.integer  "google_rank"
    t.integer  "alexa_rank"
    t.string   "path"
    t.boolean  "wildcard"
    t.string   "extra_hostnames"
    t.integer  "plan_id"
    t.integer  "pending_plan_id"
    t.integer  "next_cycle_plan_id"
    t.boolean  "cdn_up_to_date",                                :default => false
    t.datetime "first_paid_plan_started_at"
    t.datetime "plan_started_at"
    t.datetime "plan_cycle_started_at"
    t.datetime "plan_cycle_ended_at"
    t.datetime "pending_plan_started_at"
    t.datetime "pending_plan_cycle_started_at"
    t.datetime "pending_plan_cycle_ended_at"
    t.datetime "plan_player_hits_reached_notification_sent_at"
    t.datetime "first_plan_upgrade_required_alert_sent_at"
    t.integer  "last_30_days_main_player_hits_total_count",     :default => 0
    t.integer  "last_30_days_extra_player_hits_total_count",    :default => 0
    t.integer  "last_30_days_dev_player_hits_total_count",      :default => 0
  end

  add_index "sites", ["created_at"], :name => "index_sites_on_created_at"
  add_index "sites", ["hostname"], :name => "index_sites_on_hostname"
  add_index "sites", ["last_30_days_dev_player_hits_total_count"], :name => "index_sites_on_last_30_days_dev_player_hits_total_count"
  add_index "sites", ["last_30_days_extra_player_hits_total_count"], :name => "index_sites_on_last_30_days_extra_player_hits_total_count"
  add_index "sites", ["last_30_days_main_player_hits_total_count"], :name => "index_sites_on_last_30_days_main_player_hits_total_count"
  add_index "sites", ["plan_id"], :name => "index_sites_on_plan_id"
  add_index "sites", ["user_id"], :name => "index_sites_on_user_id"

  create_table "transactions", :force => true do |t|
    t.integer  "user_id"
    t.string   "order_id"
    t.string   "state"
    t.integer  "amount"
    t.text     "error"
    t.string   "pay_id"
    t.integer  "nc_status"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transactions", ["order_id"], :name => "index_transactions_on_order_id", :unique => true

  create_table "users", :force => true do |t|
    t.string   "state"
    t.string   "email",                                :default => "",   :null => false
    t.string   "encrypted_password",    :limit => 128, :default => "",   :null => false
    t.string   "password_salt",                        :default => "",   :null => false
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                      :default => 0
    t.datetime "locked_at"
    t.string   "cc_type"
    t.string   "cc_last_digits"
    t.date     "cc_expire_on"
    t.datetime "cc_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "invitation_token",      :limit => 20
    t.datetime "invitation_sent_at"
    t.integer  "zendesk_id"
    t.integer  "enthusiast_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "postal_code"
    t.string   "country"
    t.boolean  "use_personal"
    t.boolean  "use_company"
    t.boolean  "use_clients"
    t.string   "company_name"
    t.string   "company_url"
    t.string   "company_job_title"
    t.string   "company_employees"
    t.string   "company_videos_served"
    t.string   "cc_alias"
    t.string   "pending_cc_type"
    t.string   "pending_cc_last_digits"
    t.date     "pending_cc_expire_on"
    t.datetime "pending_cc_updated_at"
    t.datetime "archived_at"
    t.boolean  "newsletter",                           :default => true
    t.integer  "last_invoiced_amount",                 :default => 0
    t.integer  "total_invoiced_amount",                :default => 0
  end

  add_index "users", ["cc_alias"], :name => "index_users_on_cc_alias", :unique => true
  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["created_at"], :name => "index_users_on_created_at"
  add_index "users", ["current_sign_in_at"], :name => "index_users_on_current_sign_in_at"
  add_index "users", ["email", "archived_at"], :name => "index_users_on_email_and_archived_at", :unique => true
  add_index "users", ["last_invoiced_amount"], :name => "index_users_on_last_invoiced_amount"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["total_invoiced_amount"], :name => "index_users_on_total_invoiced_amount"

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.string   "admin_id"
    t.string   "ip"
    t.string   "user_agent"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

end
