class Admin::Admins::InvitationsController < Devise::InvitationsController
  layout 'admin'
  
  # POST /resources/invitation
  def create
    self.resource = resource_class.invite(params[resource_name])
    
    if resource.invited?
      set_flash_message(:notice, :send_instructions, :email => params[resource_name][:email])
      redirect_to send "admin_#{resource_name.to_s.pluralize}_url"
    else
      render_with_scope :new
    end
  end
  
  # GET /resources/invitation/edit?invitation_token=abcdef
  def edit
    self.resource = resource_class.find_or_initialize_with_error_by(:invitation_token, params[:invitation_token])
    render "admin/admins/invitations/edit", :layout => resource_name == :admin ? 'admin' : 'application'
  end
  
  # PUT /resources/invitation
  def update
    self.resource = resource_class.accept_invitation(params[resource_name])
    
    if resource.errors.empty?
      set_flash_message(:notice, :updated)
      sign_in resource_name, resource
      redirect_to resource_name == :admin ? admin_admins_url : sites_url
    else
      render "admin/admins/invitations/edit", :layout => resource_name == :admin ? 'admin' : 'application'
    end
  end
  
end

module DeviseInvitable
  module Controllers
    module Helpers
    protected
      def authenticate_inviter!
        authenticate_admin!
      end
    end
  end
end