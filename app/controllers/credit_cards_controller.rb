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
      if @user.valid? && @user.credit_card.valid? 
        @user.check_credit_card(options)
        if @user.d3d_html # 3-d secure identification needed
          format.html { render :text => @user.d3d_html, notice: "", alert: "" }
        else # authorized, waiting or unknown
          format.html { redirect_to [:edit, :user_registration], notice_and_alert_from_cc_authorization(@user) }
        end
      else # credit card not valid
        flash[:notice] = ""
        flash[:alert]  = ""
        format.html { render :edit }
      end
    end
  end

end
