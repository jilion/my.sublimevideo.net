class ApplicationController < ActionController::Base
  respond_to :html

  responders Responders::HttpCacheResponder

  layout 'application'

  protect_from_forgery

end
