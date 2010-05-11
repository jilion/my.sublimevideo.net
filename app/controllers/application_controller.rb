class ApplicationController < ActionController::Base
  protect_from_forgery
  responders Responders::FlashResponder, Responders::HttpCacheResponder
  
  layout 'application'
  before_filter :http_authenticate
  
protected
  
  def http_authenticate
    if (Rails.env.production? || Rails.env.staging?)
      authenticate_or_request_with_http_basic do |username, password|
        username == "jilion" && password == "H7ynww7uBJGkn8ZiaE9B"
      end
      # Devise: http://wiki.github.com/plataformatec/devise/devise-and-http-authentication
      warden.custom_failure! if performed?
    end
  end
  
end
