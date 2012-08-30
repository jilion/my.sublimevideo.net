class RenameGoodbyeFeedbacksToFeedbacks < ActiveRecord::Migration
  def up
    rename_table(:goodbye_feedbacks, :feedbacks)
  end

  def down
    rename_table(:feedbacks, :goodbye_feedbacks)
  end
end
