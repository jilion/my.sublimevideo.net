class Admin::Admins::InvitationsController < Devise::InvitationsController

  helper :all

  skip_before_filter :authenticate_user!
  layout 'admin'

  def devise_controller?
    false
  end

  # POST /invitation
  def create
    self.resource = resource_class.invite!(params[resource_name])

    if resource.invited?
      set_flash_message(:notice, :send_instructions, email: params[resource_name][:email])
      redirect_to [:admin, :admins]
    else
      render_with_scope :new
    end
  end

end
