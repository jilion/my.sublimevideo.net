class CreateTailorMadePlayerRequests < ActiveRecord::Migration
  def change
    create_table :tailor_made_player_requests do |t|
      t.string :name, :email, :topic, null: false
      t.string :job_title, :company, :url, :country, :token
      t.string :topic_standalone_detail, :topic_other_detail
      t.text :description, null: false
      t.string :document
      t.timestamps
    end
    add_index :tailor_made_player_requests, :topic
    add_index :tailor_made_player_requests, :created_at
  end
end
