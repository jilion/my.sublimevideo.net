class ApplicationController < ActionController::Base
  respond_to :html

  responders Responders::HttpCacheResponder, Responders::PaginatedResponder

  layout 'application'

  protect_from_forgery

  def zeno?
    (admin_signed_in? && current_admin.email == "zeno@jilion.com") || Rails.env.development?
  end
  helper_method :zeno?

  def mehdi?
    (admin_signed_in? && current_admin.email == "mehdi@jilion.com") || Rails.env.development?
  end
  helper_method :mehdi?

  def octave?
    (admin_signed_in? && current_admin.email == "octave@jilion.com") || Rails.env.development?
  end
  helper_method :octave?

end
