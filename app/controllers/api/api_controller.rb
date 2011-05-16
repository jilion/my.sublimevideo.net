class Api::ApiController < ActionController::Metal
  include AbstractController::Callbacks
  include ActionController::RackDelegation
  include ActionController::Helpers
  include ActionController::MimeResponds
  include ActionController::Rendering
  include ActionController::Renderers::All
  include ActionController::Instrumentation
  include Devise::Controllers::Helpers
  include ActsAsApi::Rendering

  ActsAsApi::RailsRenderer.setup

  respond_to :json

  before_filter :authenticate!

  protected

  def current_api_user
    current_api_token.user
  end

  def authenticate!
    warden.authenticate!(:scope => :api_token)
  end

  def api_template(version=1, template=:private)
    "v#{version}_#{template}".to_sym
  end

end
