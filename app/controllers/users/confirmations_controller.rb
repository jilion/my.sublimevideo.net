require_dependency 'custom_devise_paths'

class Users::ConfirmationsController < Devise::ConfirmationsController
  include CustomDevisePaths

  helper :all

end
