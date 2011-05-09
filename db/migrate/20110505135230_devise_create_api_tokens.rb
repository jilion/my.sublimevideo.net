class DeviseCreateApiTokens < ActiveRecord::Migration
  def self.up
    create_table(:api_tokens) do |t|
      t.integer :user_id
      t.trackable
      t.token_authenticatable

      t.timestamps
    end

    add_index :api_tokens, :authentication_token, :unique => true
  end

  def self.down
    drop_table :api_tokens
  end
end
