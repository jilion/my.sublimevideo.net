class CreatePlans < ActiveRecord::Migration
  def self.up
    create_table :plans do |t|
      t.string  :name
      t.string  :term_type
      t.integer :player_hits
      t.integer :price
      t.integer :overage_price
      
      t.timestamps
    end
  end

  def self.down
    drop_table :plans
  end
end