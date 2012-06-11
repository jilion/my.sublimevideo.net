require_dependency 'custom_devise_paths'

class Users::PasswordsController < Devise::PasswordsController
  include CustomDevisePaths

  helper :all

  prepend_before_filter :authenticate_scope!, only: [:validate]

  # POST /password
  def create
    if self.resource = User.not_archived.find_by_email(params[resource_name][:email])
      resource.send_reset_password_instructions
    else
      self.resource = User.new(email: params[resource_name][:email])
      resource.errors.add(:email, resource.email.present? ? :invalid : :blank)
    end

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end

  # POST /password/validate
  def validate
    @valid_password = current_user.valid_password?(params[:password])
    respond_to do |format|
      format.js
    end
  end

protected

  # Authenticates the current scope and gets the current resource from the session.
  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", force: true)
    self.resource = send(:"current_#{resource_name}")
  end

end
