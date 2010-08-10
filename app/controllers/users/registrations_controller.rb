class Users::RegistrationsController < Devise::RegistrationsController
  
  before_filter :public_required, :only => [:new, :create]
  
end