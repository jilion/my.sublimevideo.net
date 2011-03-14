class CreditCardsController < ApplicationController

  # GET /card/edit
  def edit
    @user = User.find(current_user.id)
  end

  # PUT /card
  def update
    @user = User.find(current_user.id)
    @user.attributes = params[:user]
    check_3d_secure = @user.check_credit_card(accept_url: payment_ok_transaction_url, decline_url: payment_ko_transaction_url)
    Rails.logger.info @user.errors.inspect

    respond_with(@user) do |format|
      format.html do
        if check_3d_secure.present?
          Rails.logger.info "HTML ANSWER: #{check_3d_secure}"
          render :text => check_3d_secure
        elsif @user.errors.empty?
          @user.save
          redirect_to [:edit, :user_registration]
        else
          render :edit, :status => :error
        end
      end
    end
  end

end
