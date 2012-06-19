class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices do |t|
      t.references :user

      t.string   :reference
      t.string   :state
      t.datetime :charged_at, default: nil
      t.date     :started_on
      t.date     :ended_on
      t.integer  :amount,        default: 0
      t.integer  :sites_amount, default: 0
      t.integer  :videos_amount, default: 0
      t.text     :sites
      t.text     :videos

      t.timestamps
    end

    add_index :invoices, :user_id
  end

  def self.down
    drop_table :invoices
  end
end
