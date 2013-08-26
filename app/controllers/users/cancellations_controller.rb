class Users::CancellationsController < ApplicationController
  before_filter :_set_user

  # GET /account/cancel
  def new
    @feedback = Feedback.new_account_cancellation_feedback(@user)

    respond_with(@feedback)
  end

  # POST /account/cancel
  def create
    @feedback = Feedback.new_account_cancellation_feedback(@user, _feedback_params)
    @user.attributes = _user_params

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

  def _set_user
    @user = User.find(current_user.id)
  end

  def _feedback_params
    params.require(:feedback).permit(:next_player, :comment, :reason)
  end

  def _user_params
    params.require(:user).permit(:current_password)
  end

end
