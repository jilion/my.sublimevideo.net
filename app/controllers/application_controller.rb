require 'digest/sha1'

class ApplicationController < ActionController::Base
  include CustomDevisePaths
  
  protect_from_forgery
  
  respond_to :html
  responders Responders::FlashResponder, Responders::PaginatedResponder, Responders::HttpCacheResponder
  
  layout 'application'
  
  before_filter :protection_required
  before_filter :authenticate_user!
  
protected
  
  def protection_required
    if Rails.env.production? || Rails.env.staging?
      redirect_to protection_path unless session[:protection_key] == Digest::SHA1.hexdigest("sublime-#{ENV['PROTECTION_KEY']}")
    end
  end
  
  def public_required
    redirect_to sites_path unless MySublimeVideo::Release.public?
  end
  
  module DeviseInvitable
    module Controllers
      module Helpers
      protected
        def authenticate_inviter!
          authenticate_admin!
        end
      end
    end
  end
  
end