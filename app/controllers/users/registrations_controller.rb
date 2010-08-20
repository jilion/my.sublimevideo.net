class Users::RegistrationsController < Devise::RegistrationsController
  
  before_filter :public_release_only, :only => [:new, :create]
  
end