class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices do |t|
      t.integer  :user_id
      t.string   :reference
      t.string   :state
      t.datetime :charged_at, :default => nil
      t.datetime :started_at
      t.datetime :ended_at
      t.integer  :amount,        :default => 0
      t.integer  :sites_amount, :default => 0
      t.integer  :videos_amount, :default => 0
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