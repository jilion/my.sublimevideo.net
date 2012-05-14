class GoodbyeController < ApplicationController

  before_filter :find_user

  # GET /goodbye
  def new
    @goodbye_feedback = GoodbyeFeedback.new

    respond_with(@goodbye_feedback)
  end

  # POST /goodbye
  def create
    @goodbye_feedback = GoodbyeFeedback.new(params[:goodbye_feedback])
    @user.attributes = params[:user]

    respond_to do |format|
      if GoodbyeManager.archive_user_and_save_feedback(@user, @goodbye_feedback)
        format.html do
          sign_out(@user)
          redirect_to root_url(host: request.domain, protocol: 'http')
        end
      else
        format.html { render :new }
      end
    end
  end

  private

  def find_user
    @user = User.find(current_user.id)
  end

end
