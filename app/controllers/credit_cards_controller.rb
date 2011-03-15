class CreditCardsController < ApplicationController

  # GET /card/edit
  def edit
    @user = User.find(current_user.id)
  end

  # PUT /card
  def update
    @user = User.find(current_user.id)
    @user.attributes = params[:user]
    check_3d_secure = @user.valid? && @user.check_credit_card(accept_url: ok_transaction_url, decline_url: ko_transaction_url, exception_url: ko_transaction_url)

    respond_with(@user) do |format|
      format.html do
        if check_3d_secure
          render :text => check_3d_secure
        elsif @user.errors.empty?
          @user.save
          redirect_to [:edit, :user_registration]
        else
          render :edit
        end
      end
    end
  end

end
