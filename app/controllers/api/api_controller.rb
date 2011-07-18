class Api::ApiController < ActionController::Base
  # include AbstractController::Callbacks
  # include ActionController::Helpers
  # include ActionController::MimeResponds
  # include ActionController::Rendering
  # include ActionController::Renderers::All
  # include ActionController::Instrumentation
  include Devise::Controllers::Helpers
  include ActsAsApi::Rendering
  include OAuth::Controllers::ApplicationControllerMethods

  ActsAsApi::RailsRenderer.setup

  respond_to :json, :xml

  before_filter :set_version_and_content_type
  oauthenticate

  protected

  def logged_in?
    user_signed_in?
  end

  def current_user=(user)
    sign_in(user)
  end

  protected

  def set_version_and_content_type
    version_and_content_type = (request.headers['Accept'] || '').match(%r{^application/vnd\.jilion\.sublimevideo(-v(\d+))?\+(\w+)$})
    @version = version_and_content_type.try(:[], 2) || Api.current_version
    @content_type = version_and_content_type.try(:[], 3) || params[:format] || Api.default_content_type
  end

  def api_template(template=:private)
    "v#{@version}_#{template}".to_sym
  end
  
  def access_denied
    error = { status: 401, message: "Unauthorized!" }
    render(@content_type.to_sym => error.send("to_#{@content_type}"), status: 401)
  end

end
