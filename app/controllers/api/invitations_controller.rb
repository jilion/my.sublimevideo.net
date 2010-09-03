class Api::InvitationsController < Api::ApiController
  
  # POST /api/invitations
  def create
    user = User.invite(params[:invitation]) # { :email => '...' }
    if user.invited?
      render :nothing => true, :status => :created
    else
      render :nothing => true, :status => :unprocessable_entity
    end
  end
  
end