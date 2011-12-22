class My::Users::PasswordsController < Devise::PasswordsController
  include CustomDevisePaths

  # POST /password
  def create
    self.resource = User.active.find_by_email(params[resource_name][:email]).send_reset_password_instructions()

    if successfully_sent?(resource)
      respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
    else
      respond_with_navigational(resource){ render_with_scope :new }
    end
  end

  # POST /password/validate
  def validate
    @valid_password = current_user.valid_password?(params[:password])
    respond_to do |format|
      format.js
    end
  end

end
