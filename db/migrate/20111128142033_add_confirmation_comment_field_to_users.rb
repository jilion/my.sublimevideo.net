class AddConfirmationCommentFieldToUsers < ActiveRecord::Migration
  def change
    add_column :users, :confirmation_comment, :text
  end
end
