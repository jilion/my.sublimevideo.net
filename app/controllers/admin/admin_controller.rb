class Admin::AdminController < ApplicationController
  skip_before_filter :authenticate_user!
  before_filter :authenticate_admin!
  layout 'admin'

  def require_role?(role)
    redirect_to admin_sites_url unless has_role?(role)
  end

  def has_role?(role)
    admin_signed_in? && current_admin.has_role?(role)
  end
  helper_method :has_role?

  private

  def _set_default_scopes
    params[:with_state] = 'active' if (scopes_configuration.keys & params.keys.map(&:to_sym)).empty?
    params[:by_date]    = 'desc' unless params.keys.any? { |k| k =~ /^by_\w+$/ }
  end

end
