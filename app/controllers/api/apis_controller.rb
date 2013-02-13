class Api::ApisController < ActionController::Base
  # include AbstractController::Callbacks
  # include ActionController::Head
  # include ActionController::MimeResponds
  # include ActionController::Rendering
  # include ActionController::Renderers
  # include ActionController::Renderers::All
  # include ActionController::Helpers
  # include ActionController::Instrumentation
  include Devise::Controllers::Helpers
  include OAuth::Controllers::ApplicationControllerMethods

  self.responder = ActsAsApi::Responder

  respond_to :json, :xml

  before_filter :set_version_and_content_type
  oauthenticate

  def test_request
    body = { status: 200, current_api_version: SublimeVideoApi.current_version, api_version_used: @version, token: current_token.try(:token), authorized_at: current_token.try(:authorized_at) }
    respond_to do |format|
      format.any { render(request.format.ref => body, status: 200) }
    end
  end

  protected

  def logged_in?
    user_signed_in?
  end

  def current_user=(user)
    sign_in(user)
  end

  def set_version_and_content_type
    if request.format.present?
      version_and_format = request.format.ref.to_s.match(%r{^application/vnd\.sublimevideo(-v(\d+))?\+(\w+)$})

      @version = version_and_format.try(:[], 2) || SublimeVideoApi.current_version
      request.format = params[:format] || version_and_format.try(:[], 3)
      # unknown format could lead to request.format == nil
      request.format = SublimeVideoApi.default_content_type if request.format.nil?
    end
  end

  def api_template(postfix = :private, template = :self)
    {
      prefix: "v#{@version}",
      template: template,
      postfix: postfix
    }
  end

  def access_denied
    body = { status: 401, error: "Unauthorized!" }
    render(request.format.ref => body, status: 401)
  end

end
