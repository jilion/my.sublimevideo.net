class Admin::Admins::SessionsController < Devise::SessionsController

  layout 'admin'

  private

  def has_role?(role)
    admin_signed_in? && current_admin.has_role?(role)
  end
  helper_method :has_role?

end
