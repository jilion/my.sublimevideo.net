class CreateEnthusiastsAndEnthusiastSites < ActiveRecord::Migration
  def up
    create_table "enthusiasts", force: true do |t|
      t.string   "email"
      t.text     "free_text"
      t.boolean  "interested_in_beta"
      t.string   "remote_ip"
      t.string   "confirmation_token"
      t.datetime "confirmed_at"
      t.datetime "confirmation_sent_at"
      t.datetime "trashed_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "invited_at"
      t.boolean  "starred"
      t.datetime "confirmation_resent_at"
    end
    add_index "enthusiasts", ["email"], name: "index_enthusiasts_on_email", unique: true

    create_table "enthusiast_sites", force: true do |t|
      t.integer  "enthusiast_id"
      t.string   "hostname"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "enthusiast_sites", ["enthusiast_id"], name: "index_enthusiast_sites_on_enthusiast_id"
  end

  def down
    drop_table :enthusiast_sites
    drop_table :enthusiasts
  end
end
