class Users::ConfirmationsController < Devise::ConfirmationsController
  include CustomDevisePathsControllerHelper

  helper :all
end
