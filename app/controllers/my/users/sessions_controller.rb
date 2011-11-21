class My::Users::SessionsController < Devise::SessionsController
  include CustomDevisePaths

  # GET /gs-login
  def new_gs
    render template: '/my/users/sessions/new', layout: 'popup'
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
    resource = warden.authenticate!(scope: resource_name, recall: 'com/pages#show', attempted_path: '?p=login')
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  def destroy
    cookies.delete :l, domain: :all
    super
  end

end
