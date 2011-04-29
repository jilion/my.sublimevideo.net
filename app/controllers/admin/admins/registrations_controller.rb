class Admin::Admins::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :authenticate_user!
  before_filter :authenticate_admin!
  layout 'admin'

protected

  def after_update_path_for(resource)
    edit_admin_registration_url
  end

end
