class ApplicationController < ActionController::Base
  include SublimeVideoLayout::EngineHelper
  include RedirectionFiltersControllerHelper
  include EarlyAccessControllerHelper
  include SitesControllerHelper
  include PaperTrailControllerHelper
  include CookiesControllerHelper
  include DealsControllerHelper
  include StagesControllerHelper
  include TransactionControllerHelper
  include PjaxControllerHelper
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
