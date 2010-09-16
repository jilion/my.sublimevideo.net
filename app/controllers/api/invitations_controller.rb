class Api::InvitationsController < Api::ApiController
  
  # POST /api/invitations
  def create
    email = params[:invitation] && params[:invitation][:email]
    if email && !User.exists?(:email => email.downcase) && User.invite(params[:invitation]).try(:invited?)
      render :nothing => true, :status => :created
    else
      render :nothing => true, :status => :unprocessable_entity
    end
  end
  
end