class ApplicationController < ActionController::Base
  respond_to :html
  responders Responders::HttpCacheResponder, Responders::PaginatedResponder

  protect_from_forgery
end

require "action_controller/metal"

module Devise
  class FailureApp < ActionController::Metal

    def redirect_url
      opts  = {}
      route = :"new_#{scope}_session_url"
      opts[:format] = request_format unless skip_format?
      opts[:subdomain] = case scope
                         when :user
                           'my'
                         when :admin
                           'admin'
                         else
                           nil
                         end

      if respond_to?(route)
        send(route, opts)
      else
        root_path(opts)
      end
    end

  end
end
