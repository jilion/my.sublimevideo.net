class CreditCardsController < ApplicationController
  
  # GET /card/edit
  def edit
    @user = User.find(current_user.id)
  end
  
  # PUT /card
  def update
    @user = User.find(current_user.id)
    @user.update_attributes(params[:user])
    respond_with(@user, :location => edit_user_registration_path)
  end
  
end