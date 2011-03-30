class Users::SessionsController < Devise::SessionsController

  # GET /login
  def new
    clean_up_passwords(build_resource)
    render_with_scope :new
  end

  # POST /users/sign_in
  def create
    # if params[:user] && params[:user][:email] && !params[:user][:email].include?("@jilion.com")
    #   redirect_to 'http://sublimevideo.net'
    # else
      params[:user][:email].downcase! if params[:user] && params[:user][:email]
      resource = warden.authenticate!(:scope => resource_name, :recall => "new")
      sign_in_and_redirect(resource_name, resource)
    # end
  end

  # GET /logout
  def destroy
    sign_out_and_redirect(resource_name)
  end

end
