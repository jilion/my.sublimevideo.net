require_dependency 'account_cancellation_manager'

class Users::CancellationsController < ApplicationController

  before_filter :find_user

  # GET /account/cancel
  def new
    @feedback = Feedback.new_account_cancellation_feedback

    respond_with(@feedback)
  end

  # POST /account/cancel
  def create
    @feedback = Feedback.new_account_cancellation_feedback(params[:feedback])
    @user.attributes = params[:user]

    respond_to do |format|
      if AccountCancellationManager.archive_user_and_save_feedback(@user, @feedback)
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
