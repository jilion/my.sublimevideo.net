class CreateOauthTables < ActiveRecord::Migration
  def self.up
    create_table :client_applications do |t|
      t.integer :user_id
      t.string  :name
      t.string  :url
      t.string  :support_url
      t.string  :callback_url
      t.string  :key, limit: 40
      t.string  :secret, limit: 40

      t.timestamps
    end
    add_index :client_applications, :key, unique: true

    create_table :oauth_tokens do |t|
      t.string  :type, limit: 20
      t.integer :user_id
      t.integer :client_application_id
      t.string  :token, limit: 40
      t.string  :secret, limit: 40
      t.string  :callback_url
      t.string  :verifier, limit: 20
      t.string  :scope
      t.timestamp :authorized_at, :invalidated_at, :valid_to

      t.timestamps
    end
    add_index :oauth_tokens, :token, unique: true
  end

  def self.down
    drop_table :client_applications
    drop_table :oauth_tokens
  end

end
