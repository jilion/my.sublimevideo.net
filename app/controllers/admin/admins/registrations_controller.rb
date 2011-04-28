class Admin::Admins::RegistrationsController < Devise::RegistrationsController
  before_filter :authenticate_admin!
  layout 'admin'

protected

  def after_update_path_for(resource)
    edit_admin_registration_url
  end

end
