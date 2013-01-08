class Admin::Admins::SessionsController < Devise::SessionsController

  helper :all

  layout 'admin'

  # GET /resource/sign_in
  def new
    session["#{resource_name}_return_to"] = params[:"#{resource_name}_return_to"] if params[:"#{resource_name}_return_to"]
    super
  end

end
