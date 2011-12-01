class ApplicationController < ActionController::Base
  respond_to :html
  responders Responders::HttpCacheResponder, Responders::PaginatedResponder

  protect_from_forgery

  %w[zeno mehdi octave remy thibaud].each do |name|
    method_name = "#{name}?"
    define_method(method_name) do
      (admin_signed_in? && current_admin.email == "#{name}@jilion.com") || Rails.env.development?
    end
    helper_method method_name.to_sym
  end

end
