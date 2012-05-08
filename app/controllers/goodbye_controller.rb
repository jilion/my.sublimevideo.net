class GoodbyeController < ApplicationController

  # GET /goodbye
  def new
    @user             = User.find(current_user.id)
    @goodbye_feedback = GoodbyeFeedback.new

    respond_with(@goodbye_feedback)
  end

  # POST /goodbye
  def create
    @user             = User.find(current_user.id)
    @goodbye_feedback = GoodbyeFeedback.new(params[:goodbye_feedback])

    respond_to do |format|
      if GoodbyeManager.archive_user_and_save_feedback(@user, params[:user][:current_password], @goodbye_feedback)
        format.html do
          sign_out(@user)
          redirect_to root_url(host: request.domain, protocol: 'http')
        end
      else
        format.html { render :new }
      end
    end
  end

end
