class Api::ApiController < ActionController::Metal
  include AbstractController::Callbacks
  include ActionController::Head
  include ActionController::MimeResponds
  include ActionController::Rendering
  include ActionController::Helpers
  include ActionController::Instrumentation
  include ActionController::Renderers::All
  include Devise::Controllers::Helpers
  include ActsAsApi::Rendering
  include OAuth::Controllers::ApplicationControllerMethods

  ActsAsApi::RailsRenderer.setup

  respond_to :json, :xml

  before_filter :set_version_and_content_type
  oauthenticate

  def test_request
    response = { current_api_version: Api.current_version, api_version_used: @version, token: current_token.token, authorized_at: current_token.authorized_at }
    render(request.format.ref => response, status: 200)
  end

  protected

  def logged_in?
    user_signed_in?
  end

  def current_user=(user)
    sign_in(user)
  end

  def set_version_and_content_type
    version_and_format = request.format.ref.to_s.match(%r{^application/vnd\.sublimevideo(-v(\d+))?\+(\w+)$})

    @version = version_and_format.try(:[], 2) || Api.current_version

    request.format = params[:format] || version_and_format.try(:[], 3)
    request.format = Api.default_content_type unless request.format # unknown format could lead to request.format == nil
  end

  def api_template(access=:private, template=:self)
    "v#{@version}_#{access}_#{template}".to_sym
  end

  def access_denied
    response = { error: "Unauthorized!" }
    render(request.format.ref => response, status: 401)
  end

end
