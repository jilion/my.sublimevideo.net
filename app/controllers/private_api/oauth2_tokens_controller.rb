class PrivateApi::Oauth2TokensController < SublimeVideoPrivateApiController
  before_filter :_find_oauth2_token_by_token!, only: [:show]

  # GET /private_api/oauth2_tokens/:id
  def show
    expires_in 2.minutes
    respond_with(@oauth2_token) if stale?(@oauth2_token)
  end

  private

  def _find_oauth2_token_by_token!
    @oauth2_token = Oauth2Token.valid.find_by_token!(params[:id])
  rescue ActiveRecord::RecordNotFound
    body = { error: "OAuth token #{params[:id]} could not be found." }
    render request.format.ref => body, status: 404
  end
end
