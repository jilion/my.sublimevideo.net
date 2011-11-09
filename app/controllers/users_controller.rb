class UsersController < ApplicationController
  respond_to :html

  before_filter :redirect_suspended_user

  # PUT /users/:id
  def update
    @user = User.find(current_user.id)

    respond_with(@user) do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to edit_user_registration_path }
      else
        format.html { render 'users/registrations/edit' }
      end
    end
  end

  # PUT /hide_notice/:id
  def hide_notice
    @user = User.find(current_user.id)
    @user.hidden_notice_ids << params[:id].to_i
    @user.save

    render nothing: true
  end

end
