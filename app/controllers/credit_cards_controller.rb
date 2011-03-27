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

    respond_with(@user, flash: false) do |format|
      if @user.check_credit_card(options)
        if @user.d3d_html # 3-d secure identification needed
          format.html { render :text => @user.d3d_html }
        else # authorized, waiting or unknown
          format.html { redirect_to [:edit, :user_registration], notice_and_alert_from_transaction(@user) }
        end
      else # credit card not valid
        format.html { render :edit }
      end
    end
  end

private

  def notice_and_alert_from_transaction(user)
    user.i18n_notice_and_alert ? { notice: "", alert: "" }.merge(user.i18n_notice_and_alert) : { notice: t("flash.credit_cards.update.notice"), alert: nil }
  end

end
