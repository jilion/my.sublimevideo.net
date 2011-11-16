class My::Users::SessionsController < Devise::SessionsController
  include CustomDevisePaths

  # POST /login
  def create
    resource = warden.authenticate!(scope: resource_name, recall: 'com/pages#show', attempted_path: '?p=login')
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    respond_with resource, location: redirect_location(resource_name, resource)
  end

end
