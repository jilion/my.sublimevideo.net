class UsersController < ApplicationController
  respond_to :html
  before_filter :authenticate_user!
  
  # PUT /users/1
  def update
    @user = current_user
    respond_with(@user) do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to sites_path }
      else
        format.html { render 'devise/registrations/edit' }
      end
    end
  end
  
end