require 'oauth/controllers/provider_controller'
class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController
  skip_before_filter :authenticate_user!

  def revoke
    @token = current_user.tokens.find_by_token!(params[:token])
    @token.invalidate!

    respond_with(@token) do |format|
      format.html { redirect_to(applications_url, notice: "You've revoked the authorization for the application '#{@token.client_application.name}'.") }
    end
  end

  protected

  def login_required
    authenticate_user!
  end

  def logged_in?
    user_signed_in?
  end

  # Override this to match your authorization page form
  # It currently expects a checkbox called authorize
  # def user_authorizes_token?
  #   params[:authorize] == '1'
  # end

  # should authenticate and return a user if valid password.
  # This example should work with most Authlogic or Devise. Uncomment it
  # def authenticate_user(username,password)
  #   user = User.find_by_email params[:username]
  #   if user && user.valid_password?(params[:password])
  #     user
  #   else
  #     nil
  #   end
  # end

end
