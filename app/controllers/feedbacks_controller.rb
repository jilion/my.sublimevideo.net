class FeedbacksController < ApplicationController
  before_filter :_set_user

  # GET /feedback
  def new
    @feedback = Feedback.new_trial_feedback(@user)

    respond_with(@feedback)
  end

  # POST /feedback
  def create
    @feedback = Feedback.new_trial_feedback(@user, _feedback_params)
    @feedback.user_id = current_user.id

    respond_to do |format|
      if @feedback.save
        format.html { redirect_to sites_path, notice: t('flash.feedbacks.create.notice') }
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

end
