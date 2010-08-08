class CreditCardsController < ApplicationController
  
  # GET /card/edit
  def edit
    
  end
  
  # PUT /card
  def update
    @user = User.find(current_user.id)
    respond_with(@user) do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to edit_user_registration_path, :notice => "Your credit card information was successfully (and securely) saved." }
      else
        format.html { render :edit }
      end
    end
  end
  
end