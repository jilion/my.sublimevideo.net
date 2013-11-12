require 'core_ext/hash/try_keys'

class ApplicationController < ActionController::Base
  include SublimeVideoLayout::EngineHelper
  include CookiesControllerHelper
  include DealsControllerHelper
  include EarlyAccessControllerHelper
  include PaperTrailControllerHelper
  include RedirectionFiltersControllerHelper
  include SitesControllerHelper
  include StatsControllerHelper
  include TransactionControllerHelper
  include VideosControllerHelper
  include DisplayCase::ExhibitsHelper

  helper :all
  helper_method :exhibit

  respond_to :html
  responders PaginatedResponder, Responders::HttpCacheResponder, Responders::FlashResponder

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
