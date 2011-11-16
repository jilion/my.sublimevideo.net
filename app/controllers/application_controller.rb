class ApplicationController < ActionController::Base
  respond_to :html
  responders Responders::HttpCacheResponder, Responders::PaginatedResponder
  # http_basic_authenticate_with(name: "jilion", password: ENV['PRIVATE_CODE'], realm: "Staging") if Rails.env.staging?

  protect_from_forgery

  %w[zeno mehdi octave remy thibaud].each do |name|
    method_name = "#{name}?"
    define_method(method_name) do
      (admin_signed_in? && current_admin.email == "#{name}@jilion.com") || Rails.env.development?
    end
    helper_method method_name.to_sym
  end

end
