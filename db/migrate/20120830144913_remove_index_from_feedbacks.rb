class RemoveIndexFromFeedbacks < ActiveRecord::Migration
  def up
    remove_index :feedbacks, :user_id
  end

  def down
    add_index :feedbacks, :user_id, unique: true
  end
end
