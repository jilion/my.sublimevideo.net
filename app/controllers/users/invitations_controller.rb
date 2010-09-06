class Users::InvitationsController < Devise::InvitationsController
  
  def edit
    redirect_to new_user_session_path and return unless params[:invitation_token].present?
    super
  end
  
end