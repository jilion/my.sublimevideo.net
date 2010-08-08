class UsersController < ApplicationController
  respond_to :html
  
  # PUT /users/1
  def update
    @user = User.find(current_user.id)
    respond_with(@user) do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to edit_user_registration_path }
      else
        format.html { render 'devise/registrations/edit' }
      end
    end
  end
  
end