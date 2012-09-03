class AddTypeToFeedbacks < ActiveRecord::Migration
  def change
    add_column :feedbacks, :kind, :string
  end
end
