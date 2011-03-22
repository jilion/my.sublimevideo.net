class CreateTransactionsAndInvoicesTransactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.integer :user_id
      t.string  :cc_type
      t.string  :cc_last_digits
      t.date    :cc_expire_on
      t.string  :state # unprocessed, failed, paid
      t.integer :amount # in cents
      t.string  :error_key # used for I18n translation

      # untouched params from Ogone
      t.string :pay_id     # PAYID field
      t.string :acceptance # ACCEPTANCE field
      t.string :status     # STATUS field
      t.string :eci        # ECI field
      t.string :error_code # NCERROR field
      t.text   :error      # NCERRORPLUS field

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
