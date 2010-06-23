class Admin::InvitationsController < Devise::InvitationsController
  respond_to :html
  layout 'admin'
  
protected
  
  def authenticate_resource!
    send(:"authenticate_#{resource_name}!")
  end
  
end