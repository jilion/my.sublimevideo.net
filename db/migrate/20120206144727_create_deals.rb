class CreateDeals < ActiveRecord::Migration
  def change
    create_table :deals do |t|
      t.string   :token
      t.string   :name
      t.text     :description
      t.string   :kind
      t.float    :value
      t.string   :availability_scope
      t.datetime :started_at, :ended_at

      t.timestamps
    end
    add_index :deals, :token, unique: true

    create_table :deal_activations do |t|
      t.references :deal
      t.references :user
      t.datetime :activated_at

      t.timestamps
    end
    add_index :deal_activations, [:deal_id, :user_id], unique: true

    add_column :invoice_items, :deal_id, :integer

    add_index :invoice_items, :deal_id
  end
end