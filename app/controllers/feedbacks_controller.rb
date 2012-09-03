class FeedbacksController < ApplicationController

  before_filter :find_user

  # GET /feedback
  def new
    @feedback = Feedback.new_trial_feedback

    respond_with(@feedback)
  end

  # POST /feedback
  def create
    @feedback = Feedback.new_trial_feedback(params[:feedback])
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

  def find_user
    @user = User.find(current_user.id)
  end

end
