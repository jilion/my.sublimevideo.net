class CreateAddons < ActiveRecord::Migration
  def change
    create_table :addons do |t|
      t.string  :category, null: false
      t.string  :name, null: false
      t.string  :title, null: false
      t.hstore  :settings
      t.integer :price, null: false
      t.string  :availability, null: false

      t.timestamps
    end
    add_index :addons, [:category, :name], unique: true
  end
end
