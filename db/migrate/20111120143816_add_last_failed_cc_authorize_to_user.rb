class AddLastFailedCcAuthorizeToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_failed_cc_authorize_at, :datetime
    add_column :users, :last_failed_cc_authorize_status, :integer
    add_column :users, :last_failed_cc_authorize_error, :string
  end
end