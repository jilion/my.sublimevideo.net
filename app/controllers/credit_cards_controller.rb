class CreditCardsController < ApplicationController
  before_filter do |controller|
    redirect_to([:edit, :user_registration]) unless current_user.cc?
  end

  # GET /card/edit
  def edit
    @user = User.find(current_user.id)
  end

  # PUT /card
  def update
    @user = User.find(current_user.id)
    @user.attributes = params[:user]
    options = {
      accept_url: edit_user_registration_url,
      decline_url: edit_user_registration_url,
      exception_url: edit_user_registration_url,
      ip: request.try(:remote_ip)
    }
    check_3d_secure = @user.valid? && @user.check_credit_card(options)

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
