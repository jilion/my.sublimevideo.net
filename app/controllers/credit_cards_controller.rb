class CreditCardsController < ApplicationController

  # GET /card/edit
  def edit
    @user = User.find(current_user.id)
  end

  # PUT /card
  def update
    @user = User.find(current_user.id)
    @user.attributes = params[:user]
    check_3d_secure = @user.check_credit_card
    Rails.logger.info @user.errors.inspect
    
    respond_with do |format|
      format.html do
        if check_3d_secure.present?
          html_inject = Base64.encode64(check_3d_secure)
          Rails.logger.info "HTML ANSWER: #{html_inject}"
          render :text => html_inject
        elsif @user.errors.empty?
          @user.save
          redirect_to [:edit, :user_registration]
        else
          render :edit
        end
      end
    end
  end

  def accept_3ds
    void_authorization([params["PAYID"], 'RES'].join(';'))
  end
  
  def decline_3ds
    "Credit card not accepted"
  end
  
  def exception_3ds
    "An exception occured"
  end
  
end
