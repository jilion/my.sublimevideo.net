class FeedbacksController < ApplicationController

  before_filter :_find_user

  # GET /feedback
  def new
    @feedback = Feedback.new_trial_feedback(@user)

    respond_with(@feedback)
  end

  # POST /feedback
  def create
    @feedback = Feedback.new_trial_feedback(@user, params[:feedback])
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

  def _find_user
    @user = User.find(current_user.id)
  end

end
