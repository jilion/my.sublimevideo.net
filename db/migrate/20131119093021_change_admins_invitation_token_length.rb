class ChangeAdminsInvitationTokenLength < ActiveRecord::Migration
  def change
    change_column :admins, :invitation_token, :string, limit: 255
  end
end
