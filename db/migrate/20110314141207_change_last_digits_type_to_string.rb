class ChangeLastDigitsTypeToString < ActiveRecord::Migration
  def self.up
    change_column :users, :cc_last_digits, :string
    change_column :transactions, :cc_last_digits, :string
  end

  def self.down
    change_column :transactions, :cc_last_digits, :string
    change_column :users, :cc_last_digits, :string
  end
end