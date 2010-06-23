class Admin::InvitationsController < Devise::InvitationsController
  respond_to :html
  layout 'admin'
  
  # POST /resource/invitation
  def create
    self.resource = resource_class.send_invitation(params[resource_name])

    if resource.errors.empty?
      set_flash_message :notice, :send_instructions
      redirect_to admin_admins_path
    else
      render_with_scope :new
    end
  end
  
  # PUT /resource/invitation
  def update
    self.resource = resource_class.accept_invitation!(params[resource_name])
    
    if resource.errors.empty?
      set_flash_message :notice, :updated
      sign_in resource_name, resource
      redirect_to admin_admins_path
    else
      render_with_scope :edit
    end
  end
  
end