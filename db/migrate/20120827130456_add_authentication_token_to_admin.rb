class AddAuthenticationTokenToAdmin < ActiveRecord::Migration
  def change
    add_column :admins, :authentication_token, :string
  end
end
