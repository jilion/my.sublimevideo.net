class CreateTransactionsAndInvoicesTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.integer :user_id
      t.string  :order_id
      t.string  :state    # unprocessed, failed, paid
      t.integer :amount   # in cents
      t.text    :error
      t.string  :cc_type
      t.string  :cc_last_digits
      t.date    :cc_expire_on

      # untouched params from Ogone
      t.string  :pay_id    # PAYID field
      t.integer :nc_status # NCSTATUS field
      t.integer :status    # STATUS field

      t.timestamps
    end
    add_index :transactions, :order_id, unique: true

    create_table :invoices_transactions, id: false do |t|
      t.integer :invoice_id
      t.integer :transaction_id
    end
  end

  def self.down
    drop_table :transactions
    drop_table :invoices_transactions
  end
end
