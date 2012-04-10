require 'oauth/controllers/provider_controller'

class OauthController < ApplicationController
  include OAuth::Controllers::ProviderController
  skip_before_filter :authenticate_user! # skip this since authentication is handled by OAuth::Controllers::ProviderController

  # GET /oauth/authorize
  def authorize
    params[:access_token] ||= params[:oauth_token]
    super
  end

  # POST /oauth/access_token

  # DELETE /oauth/revoke
  def revoke
    @token = current_user.tokens.find_by_token!(params[:token])
    @token.invalidate!

    respond_with(@token) do |format|
      format.html { redirect_to([:client_applications], notice: "You've revoked the authorization for the application '#{@token.client_application.name}'.") }
    end
  end

  protected

  def login_required
    authenticate_user!
  end

  def logged_in?
    user_signed_in?
  end

end
