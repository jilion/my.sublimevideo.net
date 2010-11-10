class Users::RegistrationsController < Devise::RegistrationsController
  include RedirectionFilters
  
  before_filter :only => [:update, :destroy] do |controller|
    redirect_wrong_password(resource, params[:user][:current_password])
  end
  
end