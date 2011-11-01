class AddHiddenNoticeIdsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :hidden_notice_ids, :text # serialized array
  end
end