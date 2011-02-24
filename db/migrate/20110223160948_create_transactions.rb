class CreateTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.integer :user_id
      t.string  :cc_type
      t.integer :cc_last_digits
      t.date    :cc_expire_on
      t.string  :state
      t.integer :amount
      t.text    :error

      t.timestamps
    end
  end

  def self.down
    drop_table :transactions
  end
end
