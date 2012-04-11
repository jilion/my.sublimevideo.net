class Admin::AdminController < ApplicationController
  skip_before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def require_role?(role)
    redirect_to admin_sites_url unless has_role?(role)
  end

  layout 'admin'

  def has_role?(role)
    admin_signed_in? && current_admin.has_role?(role)
  end
  helper_method :has_role?

end
