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

  oauthenticate
  before_filter :choose_version

  protected

  def logged_in?
    user_signed_in?
  end
  
  def current_user=(user)
    sign_in(user)
  end

  protected

  def choose_version
    version_and_content_type = request.headers['Accept'].match(%r{^application/vnd\.jilion\.sublimevideo(-v(\d+))?\+(\w+)$})
    @version      = version_and_content_type.try(:[], 2) || 1
    @content_type = version_and_content_type.try(:[], 3) || 'json'
  end

  def api_template(template=:private)
    "v#{@version}_#{template}".to_sym
  end

end
