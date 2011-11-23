class ApplicationController < ActionController::Base
  respond_to :html
  responders Responders::HttpCacheResponder, Responders::PaginatedResponder

  protect_from_forgery

  def cache_page
    # expires_in(1.year, public: true) if Rails.env.production?
  end

  %w[zeno mehdi octave remy thibaud].each do |name|
    method_name = "#{name}?"
    define_method(method_name) do
      (admin_signed_in? && current_admin.email == "#{name}@jilion.com") || Rails.env.development?
    end
    helper_method method_name.to_sym
  end

  # ====================
  # = Fake Maintenance =
  # ====================

  before_filter :maintenance, except: :maintenance_code
  def maintenance
    if Rails.env.production? && cookies[:maintenance] != ENV['MAINTENANCE_CODE']
      render file: File.join(Rails.root, 'public', 'maintenance.html'), layout: false
    end
  end

  # GET /private/:maintenance_code
  def maintenance_code
    cookies[:maintenance] = {
      value: params[:token],
      expires: 1.week.from_now,
      domain: :all,
      secure: true
    }
    redirect_to root_path
  end

end
