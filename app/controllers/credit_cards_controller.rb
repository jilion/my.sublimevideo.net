class CreditCardsController < ApplicationController
  
  before_filter :credit_card_needed
  
  # GET /card/edit
  def edit
    @user = User.find(current_user.id)
  end
  
  # PUT /card
  def update
    @user = User.find(current_user.id)
    respond_with(@user) do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to edit_user_registration_path }
      else
        format.html { render :edit }
      end
    end
  end
  
private
  
  def credit_card_needed
    redirect_to edit_user_registration_url unless current_user.credit_card?
  end
  
end