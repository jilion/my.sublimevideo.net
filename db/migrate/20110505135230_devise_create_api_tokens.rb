class DeviseCreateApiTokens < ActiveRecord::Migration
  def self.up
    create_table(:api_tokens) do |t|
      t.integer :user_id
      t.string :public_key
      t.string :secret_key

      t.timestamps
    end

    add_index :api_tokens, :public_key, :unique => true
    add_index :api_tokens, :secret_key, :unique => true
  end

  def self.down
    drop_table :api_tokens
  end
end
