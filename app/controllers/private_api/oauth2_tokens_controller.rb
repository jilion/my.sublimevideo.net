class PrivateApi::Oauth2TokensController < SublimeVideoPrivateApiController
  include ApisControllerHelper

  before_filter :_set_oauth2_token_by_token!, only: [:show]

  # GET /private_api/oauth2_tokens/:id
  def show
    _with_cache_control { respond_with(@oauth2_token) if stale?(@oauth2_token) }
  end

  private

  def _set_oauth2_token_by_token!
    @oauth2_token = Oauth2Token.valid.where(token: params[:id]).first!
  end
end
