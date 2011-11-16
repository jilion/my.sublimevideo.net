class ApplicationController < ActionController::Base
  respond_to :html
  responders Responders::HttpCacheResponder, Responders::PaginatedResponder
  http_basic_authenticate_with name: "jilion", password: ENV['STAGING_CODE'], realm: "Staging" if Rails.env.staging?

  layout 'application'

  protect_from_forgery

  def cache_page
    expires_in(1.year, public: true) if Rails.env.production?
  end

  %w[zeno mehdi octave remy thibaud].each do |name|
    method_name = "#{name}?"
    define_method(method_name) do
      (admin_signed_in? && current_admin.email == "#{name}@jilion.com") || Rails.env.development?
    end
    helper_method method_name.to_sym
  end

end
