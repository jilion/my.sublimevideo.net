class Users::ApiTokensController < ApplicationController
  respond_to :html

  before_filter :redirect_suspended_user

  # POST /api_tokens
  def create
    if current_user.api_token
      current_user.api_token.reset_authentication_token!
    else
      current_user.create_api_token
    end

    redirect_to edit_user_registration_path
  end

end
