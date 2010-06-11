# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100609123904) do

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

  create_table "invoices", :force => true do |t|
    t.integer  "user_id"
    t.string   "reference"
    t.string   "state"
    t.datetime "charged_at"
    t.date     "started_on"
    t.date     "ended_on"
    t.integer  "amount",        :default => 0
    t.integer  "sites_amount",  :default => 0
    t.integer  "videos_amount", :default => 0
    t.text     "sites"
    t.text     "videos"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoices", ["user_id"], :name => "index_invoices_on_user_id"

  create_table "logs", :force => true do |t|
    t.string   "name"
    t.string   "hostname"
    t.string   "state"
    t.string   "file"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "logs", ["ended_at"], :name => "index_logs_on_ended_at"
  add_index "logs", ["name"], :name => "index_logs_on_name"
  add_index "logs", ["started_at"], :name => "index_logs_on_started_at"

  create_table "site_usages", :force => true do |t|
    t.integer  "site_id"
    t.integer  "log_id"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer  "loader_hits", :default => 0
    t.integer  "player_hits", :default => 0
    t.integer  "flash_hits",  :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "site_usages", ["ended_at"], :name => "index_site_usages_on_ended_at"
  add_index "site_usages", ["site_id"], :name => "index_site_usages_on_site_id"
  add_index "site_usages", ["started_at"], :name => "index_site_usages_on_started_at"

  create_table "sites", :force => true do |t|
    t.integer  "user_id"
    t.string   "hostname"
    t.string   "dev_hostnames"
    t.string   "token"
    t.string   "license"
    t.string   "loader"
    t.string   "state"
    t.integer  "loader_hits_cache", :default => 0
    t.integer  "player_hits_cache", :default => 0
    t.integer  "flash_hits_cache",  :default => 0
    t.datetime "archived_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sites", ["created_at"], :name => "index_sites_on_created_at"
  add_index "sites", ["hostname"], :name => "index_sites_on_hostname"
  add_index "sites", ["player_hits_cache", "user_id"], :name => "index_sites_on_player_hits_cache_and_user_id"
  add_index "sites", ["user_id"], :name => "index_sites_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "state"
    t.string   "email",                                                :default => "", :null => false
    t.string   "encrypted_password",                    :limit => 128, :default => "", :null => false
    t.string   "password_salt",                                        :default => "", :null => false
    t.string   "full_name"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                                      :default => 0
    t.datetime "locked_at"
    t.integer  "invoices_count",                                       :default => 0
    t.date     "last_invoiced_on"
    t.date     "next_invoiced_on"
    t.datetime "trial_ended_at"
    t.datetime "trial_usage_information_email_sent_at"
    t.datetime "trial_usage_warning_email_sent_at"
    t.integer  "limit_alert_amount",                                   :default => 0
    t.datetime "limit_alert_email_sent_at"
    t.string   "cc_type"
    t.integer  "cc_last_digits"
    t.date     "cc_expired_on"
    t.datetime "cc_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "video_encodings", :force => true do |t|
    t.integer  "video_id"
    t.integer  "video_profile_id"
    t.integer  "video_profile_version_id"
    t.string   "state"
    t.string   "file"
    t.integer  "panda_encoding_id"
    t.datetime "started_encoding_at"
    t.integer  "encoding_time"
    t.string   "extname"
    t.integer  "file_size"
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "video_profile_versions", :force => true do |t|
    t.integer  "video_profile_id"
    t.string   "panda_profile_id"
    t.text     "note"
    t.integer  "num"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "video_profile_versions", ["video_profile_id"], :name => "index_video_profile_versions_on_video_profile_id"

  create_table "video_profiles", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "name"
    t.string   "extname"
    t.boolean  "thumbnailable"
    t.integer  "active_version_id"
    t.integer  "versions_count",    :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "videos", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.string   "token"
    t.string   "state"
    t.string   "thumbnail"
    t.integer  "hits_cache",        :default => 0
    t.integer  "bandwidth_cache",   :default => 0
    t.string   "panda_video_id"
    t.string   "original_filename"
    t.string   "video_codec"
    t.string   "audio_codec"
    t.string   "extname"
    t.integer  "file_size"
    t.integer  "duration"
    t.integer  "width"
    t.integer  "height"
    t.integer  "fps"
    t.datetime "archived_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "videos", ["created_at"], :name => "index_videos_on_created_at"
  add_index "videos", ["hits_cache"], :name => "index_videos_on_hits_cache"
  add_index "videos", ["title"], :name => "index_videos_on_title"
  add_index "videos", ["user_id"], :name => "index_videos_on_user_id"

end
