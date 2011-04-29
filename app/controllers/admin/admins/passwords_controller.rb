class Admin::Admins::PasswordsController < Devise::PasswordsController
  skip_before_filter :authenticate_user!

  layout 'admin'
end
