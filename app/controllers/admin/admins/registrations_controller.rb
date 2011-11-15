class Admin::Admins::RegistrationsController < Devise::RegistrationsController

  before_filter :authenticate_admin!
  layout 'admin'

end
