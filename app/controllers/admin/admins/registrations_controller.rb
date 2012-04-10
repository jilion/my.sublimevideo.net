class Admin::Admins::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :set_logged_in_cookie
  skip_before_filter :authenticate_user!
  before_filter :authenticate_admin!
  layout 'admin'

  private

  def has_role?(role)
    admin_signed_in? && current_admin.has_role?(role)
  end
  helper_method :has_role?

end
