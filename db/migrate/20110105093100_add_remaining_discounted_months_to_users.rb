class AddRemainingDiscountedMonthsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :remaining_discounted_months, :integer
  end

  def self.down
    remove_column :users, :remaining_discounted_months
  end
end