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
    response = @user.valid? ? @user.check_credit_card(options) : nil

    respond_with(@user) do |format|
      format.html do
        if response.nil?
          render :edit

        elsif response[:state] == "d3d"
          render :text => response[:message]

        elsif response[:state] == "authorized" && @user.save
          flash[:notice] = response[:message] if response[:message]
          redirect_to [:edit, :user_registration]
        end
      end
    end
  end

end
