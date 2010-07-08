class Admin::InvitationsController < Devise::InvitationsController
  layout 'admin'
  
  before_filter :authenticate_resource!, :only => [:new, :create]
  before_filter :require_no_authentication, :only => [:edit, :update]
  
  # GET /resource/invitation/new
  def new
    build_resource
    render_with_scope :new
  end
  
  # POST /resource/invitation
  def create
    self.resource = resource_class.send_invitation(params[resource_name])
    
    if resource.errors.empty?
      self.resource.update_attribute(:enthusiast_id, params[resource_name][:enthusiast_id]) if params[resource_name].key? :enthusiast_id
      set_flash_message :notice, :send_instructions
      redirect_to send "admin_#{resource_name.to_s.pluralize}_url"
    else
      render_with_scope :new
    end
  end
  
  # GET /resource/invitation/edit?invitation_token=abcdef
  def edit
    self.resource = resource_class.new
    resource.invitation_token = params[:invitation_token]
    render :template => "admin/invitations/edit", :layout => resource_name == :admin ? 'admin' : 'application'
  end
  
  # PUT /resource/invitation
  def update
    self.resource = resource_class.accept_invitation!(params[resource_name])
    
    if resource.errors.empty?
      set_flash_message :notice, :updated
      sign_in resource_name, resource
      redirect_to resource_name == :admin ? admin_admins_url : sites_url
    else
      render :template => "admin/invitations/edit", :layout => resource_name == :admin ? 'admin' : 'application'
    end
  end
  
protected
  
  def authenticate_resource!
    authenticate_admin!
  end
  
end