class Api::ApiController < ActionController::Metal
  include AbstractController::Callbacks
  include ActionController::RackDelegation
  include ActionController::Helpers
  include ActionController::MimeResponds
  include ActionController::Rendering
  include ActionController::Instrumentation
  include Devise::Controllers::Helpers

  respond_to :json

  before_filter :authenticate!

  protected

  def current_api_user
    current_api_token.user
  end

  def authenticate!
    warden.authenticate!(:scope => :api_token)
  end

end
