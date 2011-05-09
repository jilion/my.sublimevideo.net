class Api::ApiController < ApplicationController
  respond_to :json

  skip_before_filter :authenticate_user!
  before_filter :authenticate_api_token!

  protected

  def current_api_user
    current_api_token.user
  end

end
