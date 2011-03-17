class CreateTransactionsAndInvoicesTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.integer :user_id
      t.string  :cc_type
      t.string  :cc_last_digits
      t.date    :cc_expire_on
      t.string  :state # unprocessed, failed, paid
      t.integer :amount # in cents

      # from Ogone
      t.string :pay_id
      t.string :acceptance
      t.string :status
      t.string :eci
      t.string :error_code
      t.text   :error

      t.timestamps
    end

    create_table :invoices_transactions, :id => false do |t|
      t.integer :invoice_id
      t.integer :transaction_id
    end
  end

  def self.down
    drop_table :transactions
    drop_table :invoices_transactions
  end
end
