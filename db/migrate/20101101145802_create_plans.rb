class CreatePlans < ActiveRecord::Migration
  def self.up
    create_table :plans do |t|
      t.string  :name
      t.string  :token
      t.string  :cycle # month or year
      t.integer :player_hits
      t.integer :price

      t.timestamps
    end
    add_index :plans, [:name, :cycle], unique: true
    add_index :plans, :token, unique: true
  end

  def self.down
    drop_table :plans
  end
end
