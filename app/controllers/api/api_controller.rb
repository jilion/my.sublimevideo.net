class Api::ApiController < ActionController::Metal
  include AbstractController::Callbacks
  include ActionController::Helpers
  include ActionController::MimeResponds
  include ActionController::Rendering
  include ActionController::Renderers::All
  include ActionController::Instrumentation
  include Devise::Controllers::Helpers
  include ActsAsApi::Rendering
  include OAuth::Controllers::ApplicationControllerMethods

  ActsAsApi::RailsRenderer.setup

  respond_to :json, :xml

  before_filter :set_version_and_content_type
  oauthenticate

  def test_request
    response = { token: current_token.token, authorized_at: current_token.authorized_at }
    render(@content_type.to_sym => response.send("to_#{@content_type}"), status: 200)
  end

  protected

  def logged_in?
    user_signed_in?
  end

  def current_user=(user)
    sign_in(user)
  end

  def set_version_and_content_type
    version_and_content_type = (request.headers['Accept'] || '').match(%r{^application/vnd\.sublimevideo(-v(\d+))?\+(\w+)$})
    @version = version_and_content_type.try(:[], 2) || Api.current_version
    @content_type = version_and_content_type.try(:[], 3) || params[:format] || Api.default_content_type
  end

  def api_template(access=:private, template=:self)
    "v#{@version}_#{access}_#{template}".to_sym
  end
  
  def access_denied
    error = { error: "Unauthorized!" }
    render(@content_type.to_sym => error.send("to_#{@content_type}"), status: 401)
  end

end
