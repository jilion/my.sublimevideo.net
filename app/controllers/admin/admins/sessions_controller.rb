class Admin::Admins::SessionsController < Devise::SessionsController
  skip_before_filter :authenticate_user!

  layout 'admin'
end
