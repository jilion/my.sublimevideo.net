class ChangeNewsletterDefaultValue < ActiveRecord::Migration
  def up
    change_column_default :users, :newsletter, false
  end

  def down
    change_column_default :users, :newsletter, true
  end
end
