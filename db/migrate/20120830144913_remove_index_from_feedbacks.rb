class RemoveIndexFromFeedbacks < ActiveRecord::Migration
  def up
    # rename_index :feedbacks, 'index_goodbye_feedbacks_on_user_id', 'index_feedbacks_on_fuck'
    # remove_index :feedbacks, :fuck
  end

  def down
    add_index :feedbacks, :user_id, unique: true
    rename_index :feedbacks, 'index_feedbacks_on_user_id', 'index_goodbye_feedbacks_on_user_id'
  end
end
