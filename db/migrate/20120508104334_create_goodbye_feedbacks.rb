class CreateGoodbyeFeedbacks < ActiveRecord::Migration
  def change
    create_table :goodbye_feedbacks do |t|
      t.references :user, null: false
      t.string :next_player
      t.string :reason, null: false
      t.text :comment

      t.timestamps
    end
    add_index :goodbye_feedbacks, :user_id, unique: true
  end
end