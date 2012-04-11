class Admin::Admins::PasswordsController < Devise::PasswordsController

  helper :all

  skip_before_filter :authenticate_user!
  layout 'admin'

  private

  def has_role?(role)
    admin_signed_in? && current_admin.has_role?(role)
  end
  helper_method :has_role?

end
