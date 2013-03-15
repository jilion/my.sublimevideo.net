class Users::CancellationsController < ApplicationController

  before_filter :find_user

  # GET /account/cancel
  def new
    @feedback = Feedback.new_account_cancellation_feedback(@user)

    respond_with(@feedback)
  end

  # POST /account/cancel
  def create
    @feedback = Feedback.new_account_cancellation_feedback(@user, params[:feedback])
    @user.attributes = params[:user]

    respond_to do |format|
      if UserManager.new(@user).archive(feedback: @feedback)
        format.html do
          sign_out_and_delete_cookie
          redirect_to layout_url('')
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
