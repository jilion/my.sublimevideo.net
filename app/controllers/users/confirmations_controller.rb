require_dependency 'controller_helpers/custom_devise_paths'

class Users::ConfirmationsController < Devise::ConfirmationsController
  include ControllerHelpers::CustomDevisePaths

  helper :all

end
