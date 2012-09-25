class BillingsController < ApplicationController

  # GET /account/billing/edit
  def edit
    @user = User.find(current_user.id)
  end

  # PUT /billing
  def update
    @user = User.find(current_user.id)
    @user.assign_attributes(params[:user].merge(remote_ip: request.try(:remote_ip)))

    respond_with(@user, flash: false) do |format|
      if @user.save
        if @user.d3d_html # 3-d secure identification needed
          format.html { render text: d3d_html_inject(@user.d3d_html), notice: "", alert: "" }
        else # everything's all right
          format.html { redirect_to [:edit, :billing], notice_and_alert_from_user(@user) }
        end
      else
        flash[:notice] = flash[:alert] = ""
        format.html { render :edit }
      end
    end
  end

  private

  def notice_and_alert_from_user(user)
    if user.i18n_notice_and_alert.present?
      { notice: "", alert: "" }.merge(user.i18n_notice_and_alert)
    else
      { notice: t('flash.billings.update.notice'), alert: nil }
    end
  end

  def d3d_html_inject(text)
    "<!DOCTYPE html><html><head><title>3DS Redirection</title></head><body>#{text}</body></html>"
  end

end
