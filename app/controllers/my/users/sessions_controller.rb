class My::Users::SessionsController < Devise::SessionsController
  include CustomDevisePaths

  prepend_before_filter :require_no_authentication, only: [:new, :create, :new_gs, :create_gs]
  prepend_before_filter :allow_params_authentication!, only: [:create, :create_gs]

  # Important note: the /gs-login path is used to log-in from GetSatisfaction (it's optimized to be shown in a popup)

  # GET /gs-login
  def new_gs
    render :new, layout: 'popup'
  end

  # POST /gs-login
  def create_gs
    resource = warden.authenticate!(scope: resource_name, recall: 'my/users/sessions#new_gs')
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  # POST /login
  def create
    resource = warden.authenticate!(scope: resource_name, recall: 'my/users/sessions#new')
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    session["#{resource_name}_return_to"] = params[:success_url] if params[:success_url]
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  def destroy
    cookies.delete :l, domain: :all
    super
  end

end
