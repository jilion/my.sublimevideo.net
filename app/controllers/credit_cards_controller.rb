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

    respond_with(@user) do |format|
      case @user.check_credit_card(options)
      when "d3d"
        format.html { render :text => @user.d3d_html }

      when "authorized"
        format.html { redirect_to [:edit, :user_registration] }

      when "waiting", "unknown"
        format.html { redirect_to [:edit, :user_registration], :notice => t("credit_card.errors.#{response}") }

      else # response == "invalid", response == "refused" or user not valid
        format.html { render :edit }
      end
    end
  end

end
