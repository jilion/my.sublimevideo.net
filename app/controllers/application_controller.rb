require_dependency 'controller_helpers/redirection_filters'
require_dependency 'controller_helpers/early_access'
require_dependency 'controller_helpers/sites'
require_dependency 'controller_helpers/paper_trail'
require_dependency 'controller_helpers/cookies'
require_dependency 'controller_helpers/deals'
require_dependency 'controller_helpers/stages'
require_dependency 'controller_helpers/transaction'
require_dependency 'controller_helpers/pjax'
require_dependency 'responders/paginated_responder'

class ApplicationController < ActionController::Base
  include SublimeVideoLayout::EngineHelper
  include ControllerHelpers::RedirectionFilters
  include ControllerHelpers::EarlyAccess
  include ControllerHelpers::Sites
  include ControllerHelpers::PaperTrail
  include ControllerHelpers::Cookies
  include ControllerHelpers::Deals
  include ControllerHelpers::Stages
  include ControllerHelpers::Transaction
  include ControllerHelpers::Pjax
  include DisplayCase::ExhibitsHelper

  helper :all
  helper_method :exhibit

  respond_to :html
  responders Responders::HttpCacheResponder, Responders::PaginatedResponder, Responders::FlashResponder

  before_filter :authenticate_user!
  before_filter :set_logged_in_cookie

  protect_from_forgery

end

module DeviseInvitable::Controllers::Helpers
  protected
  def authenticate_inviter!
    authenticate_admin!
  end
end
